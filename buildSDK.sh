# need brew so for arm, do a manual clone and put vars in path
# mate ~/.zshrc 
# export PATH="/opt/homebrew/bin:/opt/homebrew/:/usr/local/bin:$PATH"

#brew install cmake
#brew install python3
#brew install ninja
 
 
# cd to a directory that is where all the build files will live (eg Documents/projects)
# we want....
# 1 Vulkan Headers
# 2 Vulkan Loader (depends on headers but script downloads that for us)
# 3 Vulkan Validation Layer (depends on headers but script downloads that for us. tests require loader but we'll skips that)
# 4 MoltenVK

https://github.com/KhronosGroup/MoltenVK.git
cd MoltenVK
 ./fetchDependencies --macos
make macos

mkdir VulkanSDK
cd VulkanSDK
mkdir macOS
mkdir macOS/include
mkdir tmp
cd tmp

#headers 162
#loader 162
#validation ?

#headers no deps
git clone --depth 1 --branch v1.2.161 https://github.com/KhronosGroup/Vulkan-Headers.git
cd Vulkan-Headers
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=install ..
make install

cd ../../

#loader dep on headers
git clone --depth 1 --branch v1.2.161 https://github.com/KhronosGroup/Vulkan-Loader.git
cd Vulkan-Loader
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
	  -DVULKAN_HEADERS_INSTALL_DIR=/Users/danielelliott/Documents/projects/vulkansdk-macos-1.2.154.0/tmp/Vulkan-Headers/build/install/ \
	  -DCMAKE_INSTALL_PREFIX=install ..
make 
make install

git clone https://github.com/KhronosGroup/glslang.git
cd glslang
./update_glslang_sources.py
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DENABLE_OPT=ON -DCMAKE_INSTALL_PREFIX=install ..
make -j 6
make install

cd ../../

git clone https://github.com/KhronosGroup/SPIRV-Headers.git
cd SPIRV-Headers
#known good with validation 1.61 fix
git checkout 5ab5c96198f30804a6a29961b8905f292a8ae600
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=install ..
cmake --build . --target install

cd ../../

# dep headers, glslang, spirv headers and spirv-tools
git clone --depth 1 --branch v1.2.162 https://github.com/KhronosGroup/Vulkan-ValidationLayers.git
cd Vulkan-ValidationLayers
# last commit at time of writing this
python3 scripts/generate_source.py /Users/danielelliott/Documents/projects/vulkansdk-macos-1.2.154.0/tmp/Vulkan-Headers/build/install/

#cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install cd Vulkan-ValidationLayers
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DVULKAN_HEADERS_INSTALL_DIR=/Users/danielelliott/Documents/projects/vulkansdk-macos-1.2.154.0/tmp/Vulkan-Headers/build/install/ \
      -DGLSLANG_INSTALL_DIR=/Users/danielelliott/Documents/projects/vulkansdk-macos-1.2.154.0/tmp/glslang/build/install/ \
      -DSPIRV_HEADERS_INSTALL_DIR=/Users/danielelliott/Documents/projects/vulkansdk-macos-1.2.154.0/tmp/SPIRV-Headers/build/install/ \
      -DCMAKE_INSTALL_PREFIX=install ..

#      -DSPIRV_TOOLS_INSTALL_DIR=absolute_path_to_install_dir \

make -j 6
make install

cd ../../

#hmm this builds glslang and build tools. chance that they clash with the previously built versions
git clone https://github.com/google/shaderc
cd shaderc 
mkdir build
mkdir install
cd build
cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install ..
ninja
ninja install


cd ../../../macOS
cp -r ../tmp/Vulkan-Headers/build/install/ .
cp -r ../tmp/Vulkan-ValidationLayers/build/install/ .
cp -r ../tmp/Vulkan-Loader/build/install/ .
cp -r ../tmp/SPIRV-Headers/build/install/ .
cp -r ../tmp/glslang/build/install/ .
cp ../tmp/Vulkan-ValidationLayers/build/layers/libVkLayer_khronos_validation.dylib lib
cp -r ../tmp/shaderc/build/install/include/shaderc include 
cp ../tmp/shaderc/build/install/lib/libshaderc* lib
cp -r ../tmp/shaderc/build/install/bin/glslc bin

cd ../
cp -r tmp/MoltenVK/Package/Release/MoltenVK .
cp MoltenVK/dylib/macOS/libMoltenVK.dylib macOS/lib


mkdir macOS/share/vulkan/icd.d	

echo "{
	\"file_format_version\": \"1.0.0\", 
    \t\"ICD\": { \
        \"library_path\": \"../../../lib/libMoltenVK.dylib\", 
        \"api_version\": \"1.1.0\" 
    }
}" > macOS/share/vulkan/icd.d/MoltenVK_icd.json



############################### old #########


cd build
../scripts/update_deps.py --config release --arch arm64
cp -r glslang/build/install/ ../../../macOS
cp -r glslang/Standalone ../../../macOS/include/glslang # for utils in vulkan hpp samples
cp -r glslang/build/Standalone/libglslang-default-resource-limits.a ../../../macOS/lib # for utils in vulkan hpp samples

cp -r Vulkan-Headers/build/install/ ../../../macOS

cmake -C helper.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../../../macOS ..
cmake --build . --parallel
make install
cp layers/libVkLayer_khronos_validation.dylib ../../../macOS/lib

# then have to edit ecplicit layers file to point to ../../../lib/validation.dynlib

cd ../../

#-DARCHITECTURE=arm64
# can update this to pass in the paths from the above libs
#cmake -H. -Bdbuild -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=build/install -DVULKAN_HEADERS_INSTALL_DIR=absolute_path_to_install_directory -DVULKAN_LOADER_INSTALL_DIR=absolute_path_to_install_directory -DVULKAN_VALIDATIONLAYERS_INSTALL_DIR=absolute_path_to_install_directory

git clone https://github.com/LunarG/VulkanTools.git
cd VulkanTools
mkdir build
mkdir install
./update_external_sources.sh #for jsoncpp
cd build
../scripts/update_deps.py
cmake -C helper.cmake ..
cmake --build . --parallel
cp layersvt/libVkLayer_api_dump.dylib ../../macinstall/lib/
cp layersvt/VkLayer_api_dump.json ../../macinstall/share/vulkan/explicit_layer.d
cp via/vkvia ../../macinstall/bin

git clone --depth 1 --branch v1.2.162 https://github.com/KhronosGroup/Vulkan-Tools.git
cd Vulkan-Tools
mkdir build
cd build
../scripts/update_deps.py --config release
cmake -C helper.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../../../macOS ..
cmake --build .
make install
cp -r MoltenVK/Package/Release/MoltenVK ../../../
cp -r MoltenVK/Package/Release/MoltenVK/dylib/macOS/libMoltenVK.dylib ../../../macOS/lib/ 
cp -r Vulkan-Loader/build/install/ ../../../macOS

mkdir ../../../macOS/share/vulkan/icd.d	

echo "{
	\"file_format_version\": \"1.0.0\", 
    \t\"ICD\": { \
        \"library_path\": \"../../../lib/libMoltenVK.dylib\", 
        \"api_version\": \"1.1.0\" 
    }
}" > ../../../macOS/share/vulkan/icd.d/MoltenVK_icd.json

cd ../../

git clone https://github.com/google/shaderc
cd shaderc 
mkdir build
mkdir install
cd build
cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../install ..
ninja
ninja install
cp -r ../install/include/shaderc ../../../macOS/include/
cp -r ../install/lib ../../../macOS/
cp -r ../install/bin ../../../macOS/
#todo shaderc
#todo libdxcompiler
#todo spirv_cross
#todo spirv-tools
