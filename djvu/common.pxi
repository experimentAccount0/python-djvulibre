# Copyright © 2008-2015 Jakub Wilk <jwilk@jwilk.net>
#
# This package is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 dated June, 1991.
#
# This package is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

include 'config.pxi'

# python-distutils preprocessor macros

cdef extern from *:
    char* PYTHON_DJVULIBRE_VERSION

# C library

from libc.stdio cimport FILE
from libc.stdlib cimport free
from libc.string cimport strlen

# Python library

from cpython.mem cimport PyMem_Malloc as py_malloc
from cpython.mem cimport PyMem_Free as py_free

from cpython.int cimport PyInt_Check as is_short_int
from cpython.long cimport PyLong_Check as is_long_int
from cpython.number cimport PyNumber_Check as is_number
from cpython.float cimport PyFloat_Check as is_float

cdef extern from 'Python.h':

    int is_slice 'PySlice_Check'(object)

    int is_unicode 'PyUnicode_Check'(object)
    int is_string 'PyString_Check'(object)
    int is_bytes 'PyBytes_Check'(object)

    object encode_utf8 'PyUnicode_AsUTF8String'(object)
    object decode_utf8_ex 'PyUnicode_DecodeUTF8'(char *, Py_ssize_t, char *)
    int bytes_to_charp 'PyBytes_AsStringAndSize'(object, char**, Py_ssize_t*) except -1
    object charp_to_bytes 'PyBytes_FromStringAndSize'(char *, Py_ssize_t)
    IF PY3K:
        object charp_to_string 'PyUnicode_FromString'(char *)
    ELSE:
        object charp_to_string 'PyString_FromString'(char *)
    int buffer_to_writable_memory 'PyObject_AsWriteBuffer'(object, void **, Py_ssize_t *)

    IF PY3K:
        object int 'PyNumber_Long'(object)
    ELSE:
        object int 'PyNumber_Int'(object)
    object bool 'PyBool_FromLong'(long)
    object voidp_to_int 'PyLong_FromVoidPtr'(void *)

    IF PY3K:
        object posix_error 'PyErr_SetFromErrno'(object)
        int file_to_fd 'PyObject_AsFileDescriptor'(object)
    ELSE:
        FILE* file_to_cfile 'PyFile_AsFile'(object)

    int list_append 'PyList_Append'(object, object) except -1

    cdef object richcmp 'PyObject_RichCompare'(object, object, int)

cdef extern from 'pythread.h':
    ctypedef void* Lock 'PyThread_type_lock'
    cdef Lock allocate_lock 'PyThread_allocate_lock'()
    cdef void free_lock 'PyThread_free_lock'(Lock lock)
    cdef int acquire_lock 'PyThread_acquire_lock'(Lock lock, int mode) nogil
    cdef void release_lock 'PyThread_release_lock'(Lock lock)

    ctypedef enum:
        WAIT_LOCK
        NOWAIT_LOCK

cdef extern from 'object.h':
    ctypedef struct PyTypeObject:
        char *tp_name
    ctypedef struct PyObject:
        PyTypeObject *ob_type
    int _typecheck 'PyObject_TypeCheck'(object o, PyTypeObject* type)

cdef int is_int(object o):
    return is_short_int(o) or is_long_int(o)

cdef object type(object o):
    return <object>((<PyObject*>o).ob_type)

IF PY3K:
    cdef object get_type_name(object type):
        return decode_utf8((<PyTypeObject*>type).tp_name)
ELSE:
    cdef char* get_type_name(object type):
        return (<PyTypeObject*>type).tp_name

cdef int typecheck(object o, object type):
    return _typecheck(o, <PyTypeObject*> type)

cdef int is_file(object o):
    IF PY3K:
        return not is_number(o) and file_to_fd(o) != -1
    ELSE:
        return typecheck(o, file)

cdef void raise_instantiation_error(object cls) except *:
    raise TypeError, 'cannot create \'{tp}\' instances'.format(tp=get_type_name(cls))

cdef object decode_utf8(char* s):
    return decode_utf8_ex(s, strlen(s), NULL)

cdef extern from 'pyerrors.h':
    ctypedef class __builtin__.Exception [object PyBaseExceptionObject]:
        pass

# vim:ts=4 sts=4 sw=4 et ft=pyrex
