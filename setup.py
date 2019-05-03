import os

from distutils.sysconfig import get_python_inc
from distutils.core import Extension, setup

try:
    from Cython.Build import cythonize
except ImportError:
    print("Please install cython and try again.")
    raise SystemExit

PACKAGES = [
    'pdsa',
    'pdsa.cardinality',
    'pdsa.membership',
    'pdsa.helpers',
    'pdsa.helpers.hashing',
    'pdsa.helpers.storage',
    'pdsa.rank',
]


def setup_package():
    root = os.path.abspath(os.path.dirname(__file__))

    with open(os.path.join(root, 'pdsa', '__about__.py')) as f:
        about = {}
        exec(f.read(), about)

    with open(os.path.join(root, 'README.rst')) as f:
        readme = f.read()

    extensions = []
    extensions.append(
        Extension(
            "pdsa.membership.bloom_filter",
            language='c++',
            sources=['pdsa/membership/bloom_filter.pyx'],
            include_dirs=[
                get_python_inc(plat_specific=True),
            ]
        )
    )
    extensions.append(
        Extension(
            "pdsa.membership.counting_bloom_filter",
            language='c++',
            sources=['pdsa/membership/counting_bloom_filter.pyx'],
            include_dirs=[
                get_python_inc(plat_specific=True),
            ]
        )
    )
    extensions.append(
        Extension(
            "pdsa.cardinality.linear_counter",
            language='c++',
            sources=['pdsa/cardinality/linear_counter.pyx'],
            include_dirs=[
                get_python_inc(plat_specific=True),
            ]
        )
    )
    extensions.append(
        Extension(
            "pdsa.cardinality.probabilistic_counter",
            language='c++',
            sources=['pdsa/cardinality/probabilistic_counter.pyx'],
            include_dirs=[
                get_python_inc(plat_specific=True),
            ]
        )
    )
    extensions.append(
        Extension(
            "pdsa.cardinality.hyperloglog",
            language='c++',
            sources=['pdsa/cardinality/hyperloglog.pyx'],
            include_dirs=[
                get_python_inc(plat_specific=True),
            ]
        )
    )
    extensions.append(
        Extension(
            "pdsa.helpers.hashing.mmh",
            language='c++',
            sources=[
                'pdsa/helpers/hashing/mmh.pyx',
                os.path.join('pdsa/helpers/hashing', 'src', 'MurmurHash3.cpp')
            ],
            include_dirs=[
                get_python_inc(plat_specific=True),
                os.path.join('pdsa/helpers/hashing', 'src')
            ]
        )
    )
    extensions.append(
        Extension(
            "pdsa.helpers.storage.bitvector",
            language='c++',
            sources=[
                'pdsa/helpers/storage/bitvector.pyx',
                os.path.join('pdsa/helpers/storage', 'src', 'BitField.cpp')
            ],
            include_dirs=[
                get_python_inc(plat_specific=True),
                os.path.join('pdsa/helpers/storage', 'src')
            ]
        )
    )
    extensions.append(
        Extension(
            "pdsa.helpers.storage.bitvector_counter",
            language='c++',
            sources=[
                'pdsa/helpers/storage/bitvector_counter.pyx',
                os.path.join('pdsa/helpers/storage', 'src', 'BitCounter.cpp')
            ],
            include_dirs=[
                get_python_inc(plat_specific=True),
                os.path.join('pdsa/helpers/storage', 'src')
            ]
        )
    )
    extensions.append(
        Extension(
            "pdsa.rank.qdigest",
            language='c++',
            sources=['pdsa/rank/qdigest.pyx'],
            include_dirs=[
                get_python_inc(plat_specific=True),
            ]
        )
    )

    setup(
        name="pdsa",
        packages=PACKAGES,
        package_data={'': ['*.pyx', '*.pxd', '*.cpp', '*.h']},
        description=about['__summary__'],
        long_description=readme,
        keywords=about['__keywords__'],
        author=about['__author__'],
        author_email=about['__email__'],
        version=about['__version__'],
        url=about['__uri__'],
        license=about['__license__'],
        ext_modules=cythonize(
            extensions,
            compiler_directives={"language_level": "3str"}
        ),
        classifiers=[
            'Environment :: Console',
            'Intended Audience :: Developers',
            'Intended Audience :: Science/Research',
            'License :: OSI Approved :: MIT License',
            'Operating System :: POSIX :: Linux',
            'Programming Language :: Cython',
            'Programming Language :: Python :: 3.5',
            'Programming Language :: Python :: 3.6',
            'Programming Language :: Python :: 3.7',
            'Topic :: Scientific/Engineering'
        ],
        requires=["cython"]
    )


if __name__ == '__main__':
    setup_package()
