import os

from distutils.sysconfig import get_python_inc
from distutils.core import Extension, setup
from Cython.Build import cythonize

PACKAGES = [
    'pds',
    'pds.membership',
    'pds.utils',
    'pds.utils.hash',
]


def setup_package():
    root = os.path.abspath(os.path.dirname(__file__))

    with open(os.path.join(root, 'pds', 'about.py')) as f:
        about = {}
        exec(f.read(), about)

    with open(os.path.join(root, 'README.rst')) as f:
        readme = f.read()

    extensions = []
    extensions.append(
        Extension(
            "pds.membership.bloom",
            language='c++',
            sources=['pds/membership/bloom.pyx'],
            include_dirs=[
                get_python_inc(plat_specific=True),
            ]
        )
    )
    extensions.append(
        Extension(
            "pds.utils.hash.mmh",
            language='c++',
            sources=[
                'pds/utils/hash/mmh.pyx',
                os.path.join('pds/utils/hash', 'src', 'MurmurHash3.cpp')
            ],
            include_dirs=[
                get_python_inc(plat_specific=True),
                os.path.join('pds/utils/hash', 'src')
            ]
        )
    )

    setup(
        name=about['__title__'],
        packages=PACKAGES,
        package_data={'': ['*.pyx', '*.pxd', '*.cpp', '*.h']},
        description=about['__summary__'],
        long_description=readme,
        author=about['__author__'],
        author_email=about['__email__'],
        version=about['__version__'],
        url=about['__uri__'],
        license=about['__license__'],
        ext_modules=cythonize(extensions),
        classifiers=[
            'Environment :: Console',
            'Intended Audience :: Developers',
            'Intended Audience :: Science/Research',
            'License :: OSI Approved :: MIT License',
            'Operating System :: POSIX :: Linux',
            'Programming Language :: Cython',
            'Programming Language :: Python :: 3.3',
            'Programming Language :: Python :: 3.4',
            'Programming Language :: Python :: 3.5',
            'Programming Language :: Python :: 3.6',
            'Topic :: Scientific/Engineering'
        ],
    )


if __name__ == '__main__':
    setup_package()
