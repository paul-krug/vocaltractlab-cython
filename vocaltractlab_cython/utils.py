
import os


def check_file_path(
    file_path: str,
    must_exist: bool = True,
    ):
    if not os.path.isfile( file_path ) and must_exist:
        raise FileNotFoundError( f'File not found: {file_path}' )
    # Check if path contains special characters
    if not file_path.isascii():
        raise ValueError(
            f'File path contains non-ascii characters: {file_path}'
            )
    return

def make_file_path( file_path: str ):
    check_file_path( file_path, must_exist=False )
    dir_path = os.path.dirname( file_path )
    if dir_path:
        os.makedirs( dir_path, exist_ok=True )
    return

def format_cstring( cString ):
    x = cString.decode()
    x = x.replace('\x00', '')
    x = x.strip(' ')
    x = x.strip('')
    x = x.split('\t')
    return x