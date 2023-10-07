import os, sys
import logging
import subprocess
import shutil
from setuptools import setup
from setuptools.extension import Extension
from Cython.Build import cythonize
import numpy as np

API_NAME = 'VocalTractLabApi'
WORKING_PATH = os.getcwd()
BACKEND_PATH = os.path.join( 'VocalTractLabBackend-dev' )
BUILD_PATH = os.path.join( BACKEND_PATH, 'out' )
API_INC_PATH = os.path.join( BACKEND_PATH, 'include', API_NAME )

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


    #api_name = 'VocalTractLabApi'
    #if sys.platform == 'win32':
    #    file_extension = '.dll'
    #    shutil.copy( os.path.join( 'Release', api_name + file_extension ), os.path.join( WORKING_PATH, 'VocalTractLab' ) )
    #    shutil.copy( os.path.join( 'Release', api_name + '.lib' ), os.path.join( WORKING_PATH, 'VocalTractLab' ) )
    #else:
    #    file_extension = '.so'
    #    try:
    #        shutil.move( 'lib' + api_name + file_extension, '/usr/local/lib/' )
    #    except Exception:
    #        print( 'WARNING: Could not move libVocalTractLabApi to standard location /usr/local/lib/ ' +
    #            ' Make shure you have permission or manually move the file to an appropriate location.' +
    #            'File is located at {}'.format( os.path.join( WORKING_PATH, 'libVocalTractLabApi.so' ) ) )

    os.chdir( WORKING_PATH )
    # Copy API header file from backend to vtl_cython
    shutil.copy(
        os.path.join(
            API_INC_PATH,
            API_NAME + '.h',
            ),
        os.path.join(
            WORKING_PATH,
            'vocaltractlab_cython',
            )
        )
    # Copy the resource folder from backend to vtl_cython
    shutil.copytree(
        os.path.join(
            BACKEND_PATH,
            'resources',
            ),
        os.path.join(
            WORKING_PATH,
            'vocaltractlab_cython',
            'resources',
            )
        )
    
    # Delete the build folder
    shutil.rmtree( BUILD_PATH )
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
    language="c++",
    libraries=[ 'vocaltractlab_cython/VocalTractLabApi' ],
    runtime_library_dirs=runtime_library_dirs,
    #extra_compile_args=['-std=c++11'],
)

#EXT_MODULES = cythonize( 'vocaltractlab_cython/VocalTractLabApi.pyx' )
EXT_MODULES = cythonize( vtl_api_extension, language="c++" )

setup_args = dict(
    #name='vocaltractlab_cython',
    #version='0.0.0',
    #description='Cython wrapper for VocalTractLabApi',
    ext_modules=EXT_MODULES,
)

setup(**setup_args)