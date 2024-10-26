import os, sys
#import logging
import subprocess
import shutil
from setuptools import setup, find_packages
from setuptools.extension import Extension
from setuptools.command.build_py import build_py
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
elif sys.platform == 'darwin':
    LIB_PATH = os.path.join(
        BACKEND_PATH,
        'lib',
        'Release',
        'libVocalTractLabApi.dylib',
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

class BuildVocalTractLabApi( build_py ):
    def run( self ):
        build_vtl_api()
        build_py.run( self )
        return
    
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
    # On Windows, copy the respective .lib file as well
    if sys.platform == 'win32':
        shutil.copy(
            LIB_PATH.replace( '.dll', '.lib' ),
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
    # For debugging purposes, ckeck if the folder already exists
    if os.path.exists( os.path.join( VTL_CYTHON_PATH, 'resources' ) ):
        shutil.rmtree( os.path.join( VTL_CYTHON_PATH, 'resources' ) )
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
    shutil.rmtree( BUILD_PATH )
    shutil.rmtree( os.path.join( BACKEND_PATH, 'lib' ) )
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
    runtime_library_dirs = [
        '@loader_path',
        os.path.join( '@loader_path', 'vocaltractlab_cython' ),
        ]
else:
    runtime_library_dirs = [ '$ORIGIN' ]#, '$ORIGIN/vocaltractlab_cython' ]

vtl_api_extension = Extension(
    'vocaltractlab_cython.VocalTractLabApi',
    sources = [
        os.path.join( 'vocaltractlab_cython', 'VocalTractLabApi.pyx' ),
        ],
    language="c",
    libraries=[
        os.path.join( 'vocaltractlab_cython', 'VocalTractLabApi' ),
        ],
    include_dirs=[ np.get_include() ],
    runtime_library_dirs=runtime_library_dirs,
    #extra_compile_args=['-std=c++11'],
)

#EXT_MODULES = cythonize( 'vocaltractlab_cython/VocalTractLabApi.pyx' )
EXT_MODULES = cythonize( vtl_api_extension )
cmdclass = dict( build_py = BuildVocalTractLabApi )

# Dependencies
DEPENDENCIES = [
    'numpy',
]

setup_args = dict(
    name = 'vocaltractlab_cython',
    version = '0.0.14.dev1',
    author='Paul Krug',
    url='https://github.com/paul-krug/vocaltractlab-cython',
    description = 'Cython wrapper for VocalTractLabApi',
    long_description_content_type='text/markdown',
    long_description=open('README.md').read(),
    license='GPL-3.0',

    ext_modules = EXT_MODULES,
    cmdclass = cmdclass,
    packages = find_packages(),#[ 'vocaltractlab_cython' ],# 'vocaltractlab_cython.resources' ],

    package_dir = dict( vocaltractlab_cython = 'vocaltractlab_cython' ),
    #data_files = [ os.path.join( BACKEND_PATH, 'src/*' ) ],

    package_data = {
        #'VocalTractLabBackend-dev': [
        #    os.path.join( BACKEND_PATH, 'src/*' ),
        #    #os.path.join( BACKEND_PATH, 'src', 'VocalTractLabBackend/*' ),
        #    #os.path.join( VTL_CYTHON_PATH, '/*' ),
        #    #os.path.join( VTL_CYTHON_PATH, 'resources/*' ),
        #    ],
        'vocaltractlab_cython': [
            #os.path.join( VTL_CYTHON_PATH ),
            os.path.join( VTL_CYTHON_PATH, '*.h' ), # Header files
            os.path.join( VTL_CYTHON_PATH, '*.dll' ), # Dynamic library, Windows
            os.path.join( VTL_CYTHON_PATH, '*.dylib' ), # Dynamic library, Mac
            os.path.join( VTL_CYTHON_PATH, '*.so' ), # Dynamic library, Linux
            os.path.join( VTL_CYTHON_PATH, 'resources/*' ), # Speaker files
            ],
    },
    include_package_data = True,
    use_scm_version = True,
    setup_requires = [ 'setuptools_scm' ],
    install_requires=DEPENDENCIES,
)

setup(**setup_args)