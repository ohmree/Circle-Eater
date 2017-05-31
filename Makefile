#**************************************************************************************************
#
#   raylib makefile for desktop platforms, Raspberry Pi and HTML5 (emscripten)
#
#   NOTE: By default examples are compiled using raylib static library and OpenAL Soft shared library
#
#   Copyright (c) 2013-2016 Ramon Santamaria (@raysan5)
#    
#   This software is provided "as-is", without any express or implied warranty. In no event 
#   will the authors be held liable for any damages arising from the use of this software.
#
#   Permission is granted to anyone to use this software for any purpose, including commercial 
#   applications, and to alter it and redistribute it freely, subject to the following restrictions:
#
#     1. The origin of this software must not be misrepresented; you must not claim that you 
#     wrote the original software. If you use this software in a product, an acknowledgment 
#     in the product documentation would be appreciated but is not required.
#
#     2. Altered source versions must be plainly marked as such, and must not be misrepresented
#     as being the original software.
#
#     3. This notice may not be removed or altered from any source distribution.
#
#**************************************************************************************************

# define raylib platform to compile for
# possible platforms: PLATFORM_DESKTOP PLATFORM_RPI PLATFORM_WEB
# WARNING: To compile to HTML5, code must be redesigned to use emscripten.h and emscripten_set_main_loop()
PLATFORM ?= PLATFORM_DESKTOP

# define NO to use OpenAL Soft as static library (shared by default)
SHARED_OPENAL ?= YES

# determine PLATFORM_OS in case PLATFORM_DESKTOP selected
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    # No uname.exe on MinGW!, but OS=Windows_NT on Windows! ifeq ($(UNAME),Msys) -> Windows
    ifeq ($(OS),Windows_NT)
        PLATFORM_OS=WINDOWS
        LIBPATH=win32
    else
        UNAMEOS:=$(shell uname)
        ifeq ($(UNAMEOS),Linux)
            PLATFORM_OS=LINUX
            LIBPATH=linux
        else
        ifeq ($(UNAMEOS),Darwin)
            PLATFORM_OS=OSX
            LIBPATH=osx
        endif
        endif
    endif
endif

# define compiler: gcc for C program, define as g++ for C++
ifeq ($(PLATFORM),PLATFORM_WEB)
    # define emscripten compiler
    CC = emcc
else
ifeq ($(PLATFORM_OS),OSX)
    # define llvm compiler for mac
    CC = clang
else
    # define default gcc compiler
    CC = gcc
endif
endif

# define compiler flags:
#  -O2         defines optimization level
#  -s          strip unnecessary data from build
#  -Wall       turns on most, but not all, compiler warnings
#  -std=c99    use standard C from 1999 revision
ifeq ($(PLATFORM),PLATFORM_RPI)
    CFLAGS = -O2 -s -Wall -std=gnu99 -fgnu89-inline
else
    CFLAGS = -O2 -s -Wall -std=c99
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    CFLAGS = -O1 -Wall -std=c99 -s USE_GLFW=3 -s ASSERTIONS=1 --preload-file resources
    #-s ALLOW_MEMORY_GROWTH=1   # to allow memory resizing
    #-s TOTAL_MEMORY=16777216   # to specify heap memory size (default = 16MB)
endif

#CFLAGSEXTRA = -Wextra -Wmissing-prototypes -Wstrict-prototypes

# define raylib release directory for compiled library
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),WINDOWS)
        RAYLIB_PATH = ../release/win32/mingw32
    endif
    ifeq ($(PLATFORM_OS),LINUX)
        RAYLIB_PATH = ../release/linux
    endif
    ifeq ($(PLATFORM_OS),OSX)
        RAYLIB_PATH = ../release/osx
    endif
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    RAYLIB_PATH = ../release/html5
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    RAYLIB_PATH = ../release/rpi
endif

# define any directories containing required header files
INCLUDES = -I. -I../src -I../src/external -I$(RAYLIB_PATH)

ifeq ($(PLATFORM),PLATFORM_RPI)
    INCLUDES += -I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads
endif
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    # add standard directories for GNU/Linux
    ifeq ($(PLATFORM_OS),LINUX)
        INCLUDES += -I/usr/local/include/raylib/
    else ifeq ($(PLATFORM_OS),WINDOWS)
        # external libraries headers
        # GLFW3
            INCLUDES += -I../src/external/glfw3/include
        # OpenAL Soft
            INCLUDES += -I../src/external/openal_soft/include
    endif
endif

# define library paths containing required libs
LFLAGS = -L. -L../src -L$(RAYLIB_PATH)

ifeq ($(PLATFORM),PLATFORM_RPI)
    LFLAGS += -L/opt/vc/lib
endif
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    # add standard directories for GNU/Linux
    ifeq ($(PLATFORM_OS),WINDOWS)
        # external libraries to link with
        # GLFW3
            LFLAGS += -L../src/external/glfw3/lib/$(LIBPATH)
        # OpenAL Soft
            LFLAGS += -L../src/external/openal_soft/lib/$(LIBPATH)
    endif
endif

# define any libraries to link into executable
# if you want to link libraries (libname.so or libname.a), use the -lname
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),LINUX)
        # libraries for Debian GNU/Linux desktop compiling
        # requires the following packages:
        # libglfw3-dev libopenal-dev libegl1-mesa-dev
        LIBS = -lraylib -lglfw3 -lGL -lopenal -lm -lpthread -ldl
        # on XWindow could require also below libraries, just uncomment
        #LIBS += -lX11 -lXrandr -lXinerama -lXi -lXxf86vm -lXcursor
    else
    ifeq ($(PLATFORM_OS),OSX)
        # libraries for OS X 10.9 desktop compiling
        # requires the following packages:
        # libglfw3-dev libopenal-dev libegl1-mesa-dev
        LIBS = -lraylib -lglfw3 -framework OpenGL -framework OpenAl -framework Cocoa
    else
        # libraries for Windows desktop compiling
        # NOTE: GLFW3 and OpenAL Soft libraries should be installed
        LIBS = -lraylib -lglfw3 -lopengl32 -lgdi32
        # if static OpenAL Soft required, define the corresponding libs
        ifeq ($(SHARED_OPENAL),NO)
            LIBS += -lopenal32 -lwinmm
            CFLAGS += -Wl,-allow-multiple-definition
        else
            LIBS += -lopenal32dll
        endif
    endif
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    # libraries for Raspberry Pi compiling
    # NOTE: OpenAL Soft library should be installed (libopenal1 package)
    LIBS = -lraylib -lGLESv2 -lEGL -lpthread -lrt -lm -lbcm_host -lopenal
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    # just adjust the correct path to libraylib.bc
    LIBS = ../release/html5/libraylib.bc
endif

# define additional parameters and flags for windows
ifeq ($(PLATFORM_OS),WINDOWS)
    # resources file contains windows exe icon
    # -Wl,--subsystem,windows hides the console window
    WINFLAGS = ../src/resources -Wl,--subsystem,windows
endif

ifeq ($(PLATFORM),PLATFORM_WEB)
    EXT = .html
endif

# define all object files required
EXAMPLES = \
    core_basic_window \
    core_input_keys \
    core_input_mouse \
    core_mouse_wheel \
    core_input_gamepad \
    core_random_values \
    core_color_select \
    core_drop_files \
    core_storage_values \
    core_gestures_detection \
    core_3d_mode \
    core_3d_picking \
    core_3d_camera_free \
    core_3d_camera_first_person \
    core_2d_camera \
    core_world_screen \
    core_oculus_rift \
    shapes_logo_raylib \
    shapes_basic_shapes \
    shapes_colors_palette \
    shapes_logo_raylib_anim \
    textures_logo_raylib \
    textures_image_loading \
    textures_rectangle \
    textures_srcrec_dstrec \
    textures_to_image \
    textures_raw_data \
    textures_formats_loading \
    textures_particles_trail_blending \
    textures_image_processing \
    textures_image_drawing \
    text_sprite_fonts \
    text_bmfont_ttf \
    text_rbmf_fonts \
    text_format_text \
    text_font_select \
    text_writing_anim \
    text_ttf_loading \
    text_bmfont_unordered \
    models_geometric_shapes \
    models_box_collisions \
    models_billboard \
    models_obj_loading \
    models_heightmap \
    models_cubicmap \
    shaders_model_shader \
    shaders_shapes_textures \
    shaders_custom_uniform \
    shaders_postprocessing \
    shaders_standard_lighting \
    audio_sound_loading \
    audio_music_stream \
    audio_module_playing \
    audio_raw_stream \
    physics_demo \
    physics_friction \
    physics_movement \
    physics_restitution \
    physics_shatter \
    fix_dylib \


# typing 'make' will invoke the default target entry called 'all',
# in this case, the 'default' target entry is raylib
all: examples

# compile all examples
examples: $(EXAMPLES)

# compile [core] example - basic window
core_basic_window: core_basic_window.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - keyboard input
core_input_keys: core_input_keys.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - mouse input
core_input_mouse: core_input_mouse.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - mouse wheel
core_mouse_wheel: core_mouse_wheel.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - gamepad input
core_input_gamepad: core_input_gamepad.c
ifeq ($(PLATFORM), $(filter $(PLATFORM),PLATFORM_DESKTOP PLATFORM_RPI))
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
else
	@echo core_input_gamepad: Example not supported on PLATFORM_ANDROID or PLATFORM_WEB
endif

# compile [core] example - generate random values
core_random_values: core_random_values.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - color selection (collision detection)
core_color_select: core_color_select.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - drop files
core_drop_files: core_drop_files.c
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
else
	@echo core_drop_files: Example not supported on PLATFORM_ANDROID or PLATFORM_WEB or PLATFORM_RPI
endif

# compile [core] example - storage values
core_storage_values: core_storage_values.c
ifeq ($(PLATFORM), $(filter $(PLATFORM),PLATFORM_DESKTOP PLATFORM_RPI))
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
else
	@echo core_storage_values: Example not supported on PLATFORM_ANDROID or PLATFORM_WEB
endif

# compile [core] example - gestures detection
core_gestures_detection: core_gestures_detection.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - 3d mode
core_3d_mode: core_3d_mode.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - 3d picking
core_3d_picking: core_3d_picking.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - 3d camera free
core_3d_camera_free: core_3d_camera_free.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - 3d camera first person
core_3d_camera_first_person: core_3d_camera_first_person.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)    

# compile [core] example - 2d camera
core_2d_camera: core_2d_camera.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [core] example - world screen
core_world_screen: core_world_screen.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [core] example - oculus rift
core_oculus_rift: core_oculus_rift.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [shapes] example - raylib logo (with basic shapes)
shapes_logo_raylib: shapes_logo_raylib.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [shapes] example - basic shapes usage (rectangle, circle, ...)
shapes_basic_shapes: shapes_basic_shapes.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [shapes] example - raylib color palette
shapes_colors_palette: shapes_colors_palette.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [shapes] example - raylib logo animation
shapes_logo_raylib_anim: shapes_logo_raylib_anim.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [textures] example - raylib logo texture loading
textures_logo_raylib: textures_logo_raylib.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [textures] example - image loading and conversion to texture
textures_image_loading: textures_image_loading.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [textures] example - texture rectangle drawing
textures_rectangle: textures_rectangle.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [textures] example - texture source and destination rectangles
textures_srcrec_dstrec: textures_srcrec_dstrec.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [textures] example - texture to image
textures_to_image: textures_to_image.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [textures] example - texture raw data
textures_raw_data: textures_raw_data.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [textures] example - texture formats loading
textures_formats_loading: textures_formats_loading.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [textures] example - texture particles trail blending
textures_particles_trail_blending: textures_particles_trail_blending.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [textures] example - texture image processing
textures_image_processing: textures_image_processing.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [textures] example - texture image drawing
textures_image_drawing: textures_image_drawing.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [text] example - sprite fonts loading
text_sprite_fonts: text_sprite_fonts.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [text] example - bmfonts and ttf loading
text_bmfont_ttf: text_bmfont_ttf.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [text] example - raylib bitmap fonts (rBMF)
text_rbmf_fonts: text_rbmf_fonts.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [text] example - text formatting
text_format_text: text_format_text.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [text] example - font selection program
text_font_select: text_font_select.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [text] example - text writing animation
text_writing_anim: text_writing_anim.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [text] example - text ttf loading
text_ttf_loading: text_ttf_loading.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [text] example - text bmfont unordered
text_bmfont_unordered: text_bmfont_unordered.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [models] example - basic geometric 3d shapes
models_geometric_shapes: models_geometric_shapes.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [models] example - box collisions
models_box_collisions: models_box_collisions.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [models] example - basic window
models_planes: models_planes.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [models] example - billboard usage
models_billboard: models_billboard.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [models] example - OBJ model loading
models_obj_loading: models_obj_loading.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [models] example - heightmap loading
models_heightmap: models_heightmap.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [models] example - cubesmap loading
models_cubicmap: models_cubicmap.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [shaders] example - model shader
shaders_model_shader: shaders_model_shader.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [shaders] example - shapes texture shader
shaders_shapes_textures: shaders_shapes_textures.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [shaders] example - custom uniform in shader
shaders_custom_uniform: shaders_custom_uniform.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)
    
# compile [shaders] example - postprocessing shader
shaders_postprocessing: shaders_postprocessing.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [shaders] example - standard lighting
shaders_standard_lighting: shaders_standard_lighting.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [audio] example - sound loading and playing (WAV and OGG)
audio_sound_loading: audio_sound_loading.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [audio] example - music stream playing (OGG)
audio_music_stream: audio_music_stream.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [audio] example - module playing (XM)
audio_module_playing: audio_module_playing.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [audio] example - raw audio streaming
audio_raw_stream: audio_raw_stream.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM) $(WINFLAGS)

# compile [physac] example - physics demo
physics_demo: physics_demo.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -lpthread -D$(PLATFORM) $(WINFLAGS)

# compile [physac] example - physics friction
physics_friction: physics_friction.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -lpthread -D$(PLATFORM) $(WINFLAGS)

# compile [physac] example - physics movement
physics_movement: physics_movement.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -lpthread -D$(PLATFORM) $(WINFLAGS)

# compile [physac] example - physics restitution
physics_restitution: physics_restitution.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -lpthread -D$(PLATFORM) $(WINFLAGS)

# compile [physac] example - physics shatter
physics_shatter: physics_shatter.c
	$(CC) -o $@$(EXT) $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -lpthread -D$(PLATFORM) $(WINFLAGS)
    
# fix dylib install path name for each executable (MAC)
fix_dylib:
ifeq ($(PLATFORM_OS),OSX)
	find . -type f -perm +ugo+x -print0 | xargs -t -0 -R 1 -I file install_name_tool -change libglfw.3.0.dylib ../external/glfw3/lib/osx/libglfw.3.0.dylib file
endif

# clean everything
clean:
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),OSX)
		find . -type f -perm +ugo+x -delete
		rm -f *.o
    else
    ifeq ($(PLATFORM_OS),LINUX)
		find -type f -executable | xargs file -i | grep -E 'x-object|x-archive|x-sharedlib|x-executable' | rev | cut -d ':' -f 2- | rev | xargs rm -f
    else
		del *.o *.exe
    endif
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
	find . -type f -executable -delete
	rm -f *.o
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
	del *.o *.html *.js
endif
	@echo Cleaning done

# instead of defining every module one by one, we can define a pattern
# this pattern below will automatically compile every module defined on $(OBJS)
#%.exe : %.c
#	$(CC) -o $@ $< $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -D$(PLATFORM)
