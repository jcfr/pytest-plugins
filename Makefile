# Package list, in order of ancestry
# removed pytest-qt-app
EXTRA_DEPS = pypandoc       \
             wheel          \
             coverage       \
             python-jenkins \
             redis          \
             pymongo        \
             psycopg2       \
             boto3          \
             "rethinkdb<2.4.0" \
             docker         \
             kubernetes

COPY_FILES = VERSION CHANGES.md common_setup.py MANIFEST.in LICENSE
UPLOAD_OPTS =

# removed from PHONY:  circleci_sip circleci_pyqt
.PHONY: extras copyfiles wheels sdists install develop test upload clean

extras:
	pip install $(EXTRA_DEPS)

copyfiles:
	./foreach.sh 'for file in $(COPY_FILES); do cp ../$$file .; done'

wheels: copyfiles
	pip install -U wheel
	./foreach.sh --changed 'python setup.py bdist_wheel'

sdists: copyfiles
	./foreach.sh --changed 'python setup.py sdist'

install: copyfiles
	pip install -U wheel
	./foreach.sh 'python setup.py bdist_wheel'
	./foreach.sh 'pip install dist/*.whl'

develop: copyfiles extras
	./foreach.sh 'pip install -e.[tests]'

test:
	rm -f FAILED-*
	./foreach.sh 'DEBUG=1 python setup.py test || touch ../FAILED-$$PKG'
	bash -c "! compgen -G 'FAILED-*'"

upload:
	pip install twine
	./foreach.sh --changed '[ -f common_setup.py ] && twine upload $(UPLOAD_OPTS) dist/*'

clean:
	./foreach.sh 'rm -rf build dist *.xml *.egg-info .eggs htmlcov .cache $(COPY_FILES)'
	rm -rf pytest-pyramid-server/vx pip-log.txt
	find . -name *.pyc -delete
	find . -name .coverage -delete
	find . -name .coverage.* -delete
	rm -f FAILED-*

all: extras develop test
