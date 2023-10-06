import os, sys
import logging
import subprocess
import shutil
from setuptools import setup
from setuptools.extension import Extension
from Cython.Build import cythonize
import numpy as np

WORKING_PATH = os.getcwd()
BACKEND_PATH = os.path.join( 'vocaltractlab_cython', 'src', 'vocaltractlab-backend' )

def build_vtl_api():
    print( 'Building VocalTractLab-Backend using cmake:' )
    os.chdir( BACKEND_PATH )
    #with TemporaryDirectory() as tmpdir:
    #    os.chdir(tmpdir)
    #subprocess.check_call( [ 'cmake', '.' ] )
    #subprocess.check_call( [ 'cmake', '--build', '.', '--config', 'Release' ] )
    subprocess.check_call( [ 'cmake', '.', '-DCMAKE_BUILD_TYPE=Release' ] )
    subprocess.check_call( [ 'cmake', '--build', '.', '--target', 'VocalTractLabApi', '--config', 'Release' ] )

    api_name = 'VocalTractLabApi'
    if sys.platform == 'win32':
        file_extension = '.dll'
        shutil.copy( os.path.join( 'Release', api_name + file_extension ), os.path.join( WORKING_PATH, 'VocalTractLab' ) )
        shutil.copy( os.path.join( 'Release', api_name + '.lib' ), os.path.join( WORKING_PATH, 'VocalTractLab' ) )
    #else:
    #    file_extension = '.so'
    #    try:
    #        shutil.move( 'lib' + api_name + file_extension, '/usr/local/lib/' )
    #    except Exception:
    #        print( 'WARNING: Could not move libVocalTractLabApi to standard location /usr/local/lib/ ' +
    #            ' Make shure you have permission or manually move the file to an appropriate location.' +
    #            'File is located at {}'.format( os.path.join( WORKING_PATH, 'libVocalTractLabApi.so' ) ) )
    shutil.copy( os.path.join( '', api_name + '.h' ), os.path.join( WORKING_PATH, 'VocalTractLab' ) )
    #print( ' chir dir: ' )
    #print( os.listdir( os.getcwd() ) )
    os.chdir( WORKING_PATH )
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

vtl_api_extension = Extension(
    'vocaltractlab_cython.VocalTractLabApi',
    sources = [
        'vocaltractlab_cython/VocalTractLabApi.pyx',
        'vocaltractlab_cython/src/vocaltractlab-backend/AnatomyParams.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/Dsp.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/F0EstimatorYin.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/GeometricGlottis.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/Geometry.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/GesturalScore.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/Glottis.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/IirFilter.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/ImpulseExcitation.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/LfPulse.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/Matrix2x2.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/PoleZeroPlan.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/Sampa.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/SegmentSequence.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/StaticPhone.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/Surface.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/Synthesizer.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/TdsModel.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/TimeFunction.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/TlModel.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/TriangularGlottis.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/Tube.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/TwoMassModel.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/VocalTract.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/VocalTractLabApi.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/VoiceQualityEstimator.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/VowelLf.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/XmlHelper.cpp',
        'vocaltractlab_cython/src/vocaltractlab-backend/XmlNode.cpp',
        ],
    language="c++",
    extra_compile_args=['-std=c++11'],
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