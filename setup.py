# ecoding=UTF-8
# Copyright © 2007, 2008 Jakub Wilk <ubanus@users.sf.net>

from distutils.core import setup
from distutils.extension import Extension
from Pyrex.Distutils import build_ext
from subprocess import Popen, PIPE

EXT_MODULES = ('decode', 'sexpr')

def get_version():
	from sys import path
	from os.path import join as path_join
	from re import match
	changelog = file(path_join(path[0], 'ChangeLog'))
	try:
		line = changelog.readline()
		m = match('python-djvulibre [(]([0-9.]+)[)]', line)
		return m.group(1)
	finally:
		changelog.close()

PKG_CONFIG_FLAG_MAP = {'-I': 'include_dirs', '-L': 'library_dirs', '-l': 'libraries'}

def pkg_config(*packages, **kwargs):
	pkgconfig = Popen(
		['pkg-config', '--libs', '--cflags'] + list(packages),
		stdout = PIPE, stderr = PIPE
	)
	stdout, stderr = pkgconfig.communicate()
	if pkgconfig.returncode:
		raise IOError('[pkg-config] ' + stderr.strip())
	kwargs.setdefault('extra_link_args', [])
	kwargs.setdefault('extra_compile_args', ['-Wno-uninitialized'])
	for argument in stdout.split():
		key = argument[:2]
		try:
			value = argument[2:]
			kwargs.setdefault(PKG_CONFIG_FLAG_MAP[key], []).append(value)
		except KeyError:
			kwargs['extra_link_args'].append(argument)
			kwargs['extra_compile_args'].append(argument)
	return kwargs

__version__ = get_version()

setup(
	name = 'python-djvulibre',
	version = __version__,
	author = 'Jakub Wilk',
	author_email = 'ubanus@users.sf.net',
	license = 'GNU GPL 2',
	platforms = ['all'],
	ext_package = 'djvu',
	ext_modules = \
	[
		Extension(
			name, ['djvu.%s.pyx' % name],
			**pkg_config(
				'ddjvuapi',
				define_macros = [('PYTHON_DJVULIBRE_VERSION', '"%s"' % __version__)]
			)
		)
		for name in EXT_MODULES
	],
	py_modules = ['djvu.const'],
	cmdclass = dict(build_ext = build_ext)
)

# vim:ts=4 sw=4 noet
