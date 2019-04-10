.PHONY: install clean test

SHELL = /bin/bash
PYTHON = $(shell which python3)

default: bin/python3

bin/python3:
	virtualenv . -p ${PYTHON} --no-site-packages
	bin/pip3 install --upgrade pip wheel
	bin/pip3 install -r requirements.txt

build: bin/python3
	bin/python3 setup.py build_py
	bin/python3 setup.py build_ext --inplace

install: build
	bin/python3 setup.py install

clean:
	# virtualenv
	rm -Rf bin include lib local share
	# buildout and pip
	rm -Rf develop-eggs eggs *.egg-info
	rm -Rf src parts build dist
	rm -Rf .installed.cfg pip-selfcheck.json
	rm -Rf cythonize.json

test:
	bin/py.test -m 'not ignore' --pep8 tests
