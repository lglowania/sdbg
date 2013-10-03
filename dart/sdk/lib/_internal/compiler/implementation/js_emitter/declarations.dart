// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

/// Enables debugging of fast/slow objects using V8-specific primitives.
const DEBUG_FAST_OBJECTS = false;

/**
 * A convenient type alias for some functions that emit keyed values.
 */
typedef void DefineStubFunction(String invocationName, jsAst.Expression value);

/**
 * [member] is a field (instance, static, or top level).
 *
 * [name] is the field name that the [Namer] has picked for this field's
 * storage, that is, the JavaScript property name.
 *
 * [accessorName] is the name of the accessor. For instance fields this is
 * mostly the same as [name] except when [member] is shadowing a field in its
 * superclass.  For other fields, they are rarely the same.
 *
 * [needsGetter] and [needsSetter] represent if a getter or a setter
 * respectively is needed.  There are many factors in this, for example, if the
 * accessor can be inlined.
 *
 * [needsCheckedSetter] indicates that a checked getter is needed, and in this
 * case, [needsSetter] is always false. [needsCheckedSetter] is only true when
 * type assertions are enabled (checked mode).
 */
typedef void AcceptField(VariableElement member,
                         String name,
                         String accessorName,
                         bool needsGetter,
                         bool needsSetter,
                         bool needsCheckedSetter);

// Function signatures used in the generation of runtime type information.
typedef void FunctionTypeSignatureEmitter(Element method,
                                          FunctionType methodType);

// TODO(johnniwinther): Clean up terminology for rti in the emitter.
typedef void FunctionTypeTestEmitter(FunctionType functionType);

typedef void SubstitutionEmitter(Element element, {bool emitNull});

const String GENERATED_BY = """
// Generated by dart2js, the Dart to JavaScript compiler.
""";

const String HOOKS_API_USAGE = """
// The code supports the following hooks:
// dartPrint(message)   - if this function is defined it is called
//                        instead of the Dart [print] method.
// dartMainRunner(main) - if this function is defined, the Dart [main]
//                        method will not be invoked directly.
//                        Instead, a closure that will invoke [main] is
//                        passed to [dartMainRunner].
""";

// Compact field specifications.  The format of the field specification is
// <accessorName>:<fieldName><suffix> where the suffix and accessor name
// prefix are optional.  The suffix directs the generation of getter and
// setter methods.  Each of the getter and setter has two bits to determine
// the calling convention.  Setter listed below, getter is similar.
//
//     00: no setter
//     01: function(value) { this.field = value; }
//     10: function(receiver, value) { receiver.field = value; }
//     11: function(receiver, value) { this.field = value; }
//
// The suffix encodes 4 bits using three ASCII ranges of non-identifier
// characters.
const FIELD_CODE_CHARACTERS = r"<=>?@{|}~%&'()*";
const NO_FIELD_CODE = 0;
const FIRST_FIELD_CODE = 1;
const RANGE1_FIRST = 0x3c;   //  <=>?@    encodes 1..5
const RANGE1_LAST = 0x40;
const RANGE2_FIRST = 0x7b;   //  {|}~     encodes 6..9
const RANGE2_LAST = 0x7e;
const RANGE3_FIRST = 0x25;   //  %&'()*+  encodes 10..16
const RANGE3_LAST = 0x2b;
const REFLECTION_MARKER = 0x2d;