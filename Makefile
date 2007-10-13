.PHONY: all
all:
	python setup.py build_ext --inplace

.PHONY: test
test: test-miniexp test-ddjvu

test-miniexp: all
	python tests/miniexp.py

test-ddjvu: all
	python tests/ddjvu.py

.PHONY: clean
clean:
	$(RM) *.c *.o *.so
	$(RM) -R build/

# vim:ts=4 sw=4 noet
