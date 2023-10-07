import os, sys
#import logging
import subprocess
import shutil
from setuptools import setup
from setuptools.extension import Extension
from Cython.Build import cythonize
import numpy as np

API_NAME = 'VocalTractLabApi'
WORKING_PATH = os.getcwd()
VTL_CYTHON_PATH = os.path.join( WORKING_PATH, 'vocaltractlab_cython' )
BACKEND_PATH = os.path.join( 'VocalTractLabBackend-dev' )
BUILD_PATH = os.path.join( BACKEND_PATH, 'out' )
API_INC_PATH = os.path.join( BACKEND_PATH, 'include', API_NAME )
if sys.platform == 'win32':
    LIB_PATH = os.path.join(
        BACKEND_PATH,
        'lib',
        'Release',
        'VocalTractLabApi.dll',
        )
else:
    LIB_PATH = os.path.join(
        BACKEND_PATH,
        'lib',
        'Release',
        'libVocalTractLabApi.so',
        )

cmd_config = [
    'cmake',
    '..',
    '-DCMAKE_BUILD_TYPE=Release',
    ]

cmd_build = [
    'cmake',
    '--build',
    '.',
    '--config',
    'Release',
    '--target',
    'VocalTractLabApi',
    ]

def build_vtl_api():
    print( 'Building VocalTractLab-Backend using cmake:' )
    os.makedirs( BUILD_PATH, exist_ok=True )
    os.chdir( BUILD_PATH )
    #with TemporaryDirectory() as tmpdir:
    #    os.chdir(tmpdir)
    
    subprocess.check_call( cmd_config )
    subprocess.check_call( cmd_build )

    os.chdir( WORKING_PATH )
        
    # Copy the library file from backend to vtl_cython
    shutil.copy(
        LIB_PATH,
        VTL_CYTHON_PATH,
        )
    # Copy API header file from backend to vtl_cython
    shutil.copy(
        os.path.join(
            API_INC_PATH,
            API_NAME + '.h',
            ),
        VTL_CYTHON_PATH,
        )
    # Copy the resource folder from backend to vtl_cython
    shutil.copytree(
        os.path.join(
            BACKEND_PATH,
            'resources',
            ),
        os.path.join(
            VTL_CYTHON_PATH,
            'resources',
            )
        )
    
    # Delete the build folder
    #shutil.rmtree( BUILD_PATH )
    return


#vtl_api_extension = Extension(
#    'vocaltractlab_cython.VocalTractLabApi',
#    [ './vocaltractlab_cython/VocalTractLabApi.pyx' ],
#    language="c",
#    libraries=[ 'VocalTractLabApi' ],
#    library_dirs=[ './vocaltractlab_cython/src/vocaltractlab-backend' ],
#    include_dirs=[ np.get_include(), './vocaltractlab_cython/src/vocaltractlab-backend' ],
#    #runtime_library_dirs=runtime_library_dirs #'./', './VocalTractLab/', './VocalTractLab/VocalTractLabApi' ],
#    )

#build_vtl_api()
#stop

if sys.platform == 'win32':
    runtime_library_dirs = None
elif sys.platform == 'darwin':
    runtime_library_dirs = [ '@loader_path', '@loader_path/VocalTractLab' ]
else:
    runtime_library_dirs = [ '$ORIGIN' ]#, '$ORIGIN/VocalTractLab' ]

vtl_api_extension = Extension(
    'vocaltractlab_cython.VocalTractLabApi',
    sources = [
        'vocaltractlab_cython/VocalTractLabApi.pyx',
        ],
    language="c",
    libraries=[ 'vocaltractlab_cython/VocalTractLabApi' ],
    include_dirs=[ np.get_include() ],
    runtime_library_dirs=runtime_library_dirs,
    #extra_compile_args=['-std=c++11'],
)

#EXT_MODULES = cythonize( 'vocaltractlab_cython/VocalTractLabApi.pyx' )
EXT_MODULES = cythonize( vtl_api_extension )

setup_args = dict(
    #name='vocaltractlab_cython',
    #version='0.0.0',
    #description='Cython wrapper for VocalTractLabApi',
    ext_modules=EXT_MODULES,
)

setup(**setup_args)