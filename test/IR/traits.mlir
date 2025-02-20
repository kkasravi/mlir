// RUN: mlir-opt %s -split-input-file -verify-diagnostics | FileCheck %s

// CHECK: succeededSameOperandsElementType
func @succeededSameOperandsElementType(%t10x10 : tensor<10x10xf32>, %t1f: tensor<1xf32>, %v1: vector<1xf32>, %t1i: tensor<1xi32>, %sf: f32) {
  "test.same_operand_element_type"(%t1f, %t1f) : (tensor<1xf32>, tensor<1xf32>) -> tensor<1xi32>
  "test.same_operand_element_type"(%t1f, %t10x10) : (tensor<1xf32>, tensor<10x10xf32>) -> tensor<1xi32>
  "test.same_operand_element_type"(%t10x10, %v1) : (tensor<10x10xf32>, vector<1xf32>) -> tensor<1xi32>
  "test.same_operand_element_type"(%v1, %t1f) : (vector<1xf32>, tensor<1xf32>) -> tensor<1xi32>
  "test.same_operand_element_type"(%v1, %t1f) : (vector<1xf32>, tensor<1xf32>) -> tensor<121xi32>
  "test.same_operand_element_type"(%sf, %sf) : (f32, f32) -> i32
  "test.same_operand_element_type"(%sf, %t1f) : (f32, tensor<1xf32>) -> tensor<121xi32>
  "test.same_operand_element_type"(%sf, %v1) : (f32, vector<1xf32>) -> tensor<121xi32>
  "test.same_operand_element_type"(%sf, %t10x10) : (f32, tensor<10x10xf32>) -> tensor<121xi32>
  return
}

// -----

func @failedSameOperandElementType(%t1f: tensor<1xf32>, %t1i: tensor<1xi32>) {
  // expected-error@+1 {{requires the same element type for all operands}}
  "test.same_operand_element_type"(%t1f, %t1i) : (tensor<1xf32>, tensor<1xi32>) -> tensor<1xf32>
}

// -----

func @failedSameOperandAndResultElementType_no_operands() {
  // expected-error@+1 {{expected 1 or more operands}}
  "test.same_operand_element_type"() : () -> tensor<1xf32>
}

// -----

func @failedSameOperandElementType_scalar_type_mismatch(%si: i32, %sf: f32) {
  // expected-error@+1 {{requires the same element type for all operands}}
  "test.same_operand_element_type"(%sf, %si) : (f32, i32) -> tensor<1xf32>
}

// -----

// CHECK: succeededSameOperandAndResultElementType
func @succeededSameOperandAndResultElementType(%t10x10 : tensor<10x10xf32>, %t1f: tensor<1xf32>, %v1: vector<1xf32>, %t1i: tensor<1xi32>, %sf: f32) {
  "test.same_operand_and_result_element_type"(%t1f, %t1f) : (tensor<1xf32>, tensor<1xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_element_type"(%t1f, %t10x10) : (tensor<1xf32>, tensor<10x10xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_element_type"(%t10x10, %v1) : (tensor<10x10xf32>, vector<1xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_element_type"(%v1, %t1f) : (vector<1xf32>, tensor<1xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_element_type"(%v1, %t1f) : (vector<1xf32>, tensor<1xf32>) -> tensor<121xf32>
  "test.same_operand_and_result_element_type"(%sf, %sf) : (f32, f32) -> f32
  "test.same_operand_and_result_element_type"(%sf, %t1f) : (f32, tensor<1xf32>) -> tensor<121xf32>
  "test.same_operand_and_result_element_type"(%sf, %v1) : (f32, vector<1xf32>) -> tensor<121xf32>
  "test.same_operand_and_result_element_type"(%sf, %t10x10) : (f32, tensor<10x10xf32>) -> tensor<121xf32>
  return
}

// -----

func @failedSameOperandAndResultElementType_operand_result_mismatch(%t1f: tensor<1xf32>) {
  // expected-error@+1 {{requires the same element type for all operands and results}}
  "test.same_operand_and_result_element_type"(%t1f, %t1f) : (tensor<1xf32>, tensor<1xf32>) -> tensor<1xi32>
}

// -----

func @failedSameOperandAndResultElementType_operand_mismatch(%t1f: tensor<1xf32>, %t1i: tensor<1xi32>) {
  // expected-error@+1 {{requires the same element type for all operands and results}}
  "test.same_operand_and_result_element_type"(%t1f, %t1i) : (tensor<1xf32>, tensor<1xi32>) -> tensor<1xf32>
}

// -----

func @failedSameOperandAndResultElementType_result_mismatch(%t1f: tensor<1xf32>) {
  // expected-error@+1 {{requires the same element type for all operands and results}}
  %0:2 = "test.same_operand_and_result_element_type"(%t1f) : (tensor<1xf32>) -> (tensor<1xf32>, tensor<1xi32>)
}

// -----

func @failedSameOperandAndResultElementType_no_operands() {
  // expected-error@+1 {{expected 1 or more operands}}
  "test.same_operand_and_result_element_type"() : () -> tensor<1xf32>
}

// -----

func @failedSameOperandAndResultElementType_no_results(%t1f: tensor<1xf32>) {
  // expected-error@+1 {{expected 1 or more results}}
  "test.same_operand_and_result_element_type"(%t1f) : (tensor<1xf32>) -> ()
}

// -----

// CHECK: succeededSameOperandShape
func @succeededSameOperandShape(%t10x10 : tensor<10x10xf32>, %t1: tensor<1xf32>, %m10x10 : memref<10x10xi32>, %tr: tensor<*xf32>) {
  "test.same_operand_shape"(%t1, %t1) : (tensor<1xf32>, tensor<1xf32>) -> ()
  "test.same_operand_shape"(%t10x10, %t10x10) : (tensor<10x10xf32>, tensor<10x10xf32>) -> ()
  "test.same_operand_shape"(%t1, %tr) : (tensor<1xf32>, tensor<*xf32>) -> ()
  "test.same_operand_shape"(%t10x10, %m10x10) : (tensor<10x10xf32>, memref<10x10xi32>) -> ()
  return
}

// -----

func @failedSameOperandShape_operand_mismatch(%t10x10 : tensor<10x10xf32>, %t1: tensor<1xf32>) {
  // expected-error@+1 {{requires the same shape for all operands}}
  "test.same_operand_shape"(%t1, %t10x10) : (tensor<1xf32>, tensor<10x10xf32>) -> ()
}

// -----

func @failedSameOperandShape_no_operands() {
  // expected-error@+1 {{expected 1 or more operands}}
  "test.same_operand_shape"() : () -> ()
}

// -----

// CHECK: succeededSameOperandAndResultShape
func @succeededSameOperandAndResultShape(%t10x10 : tensor<10x10xf32>, %t1: tensor<1xf32>, %tr: tensor<*xf32>, %t1d: tensor<?xf32>) {
  "test.same_operand_and_result_shape"(%t1, %t1) : (tensor<1xf32>, tensor<1xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_shape"(%t10x10, %t10x10) : (tensor<10x10xf32>, tensor<10x10xf32>) -> tensor<10x10xf32>
  "test.same_operand_and_result_shape"(%t1, %tr) : (tensor<1xf32>, tensor<*xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_shape"(%t1, %t1d) : (tensor<1xf32>, tensor<?xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_shape"(%t1, %t1d) : (tensor<1xf32>, tensor<?xf32>) -> memref<1xf32>

  return
}

// -----

func @failedSameOperandAndResultShape_operand_result_mismatch(%t10x10 : tensor<10x10xf32>, %t1: tensor<1xf32>) {
  // expected-error@+1 {{requires the same shape for all operands and results}}
  "test.same_operand_and_result_shape"(%t1, %t10x10) : (tensor<1xf32>, tensor<10x10xf32>) -> tensor<10x10xf32>
}

// -----

func @failedSameOperandAndResultShape_no_operands() {
  // expected-error@+1 {{expected 1 or more operands}}
  "test.same_operand_and_result_shape"() : () -> (tensor<1xf32>)
}

// -----

func @failedSameOperandAndResultShape_no_operands(%t1: tensor<1xf32>) {
  // expected-error@+1 {{expected 1 or more results}}
  "test.same_operand_and_result_shape"(%t1) : (tensor<1xf32>) -> ()
}

// -----

// CHECK: succeededSameOperandAndResultType
func @succeededSameOperandAndResultType(%t10x10 : tensor<10x10xf32>, %t1: tensor<1xf32>, %tr: tensor<*xf32>, %t1d: tensor<?xf32>, %i32 : i32) {
  "test.same_operand_and_result_type"(%t1, %t1) : (tensor<1xf32>, tensor<1xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_type"(%t10x10, %t10x10) : (tensor<10x10xf32>, tensor<10x10xf32>) -> tensor<10x10xf32>
  "test.same_operand_and_result_type"(%t1, %tr) : (tensor<1xf32>, tensor<*xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_type"(%t1, %t1d) : (tensor<1xf32>, tensor<?xf32>) -> tensor<1xf32>
  "test.same_operand_and_result_type"(%i32, %i32) : (i32, i32) -> i32
  return
}

// -----

func @failedSameOperandAndResultType_operand_result_mismatch(%t10 : tensor<10xf32>, %t20 : tensor<20xf32>) {
  // expected-error@+1 {{requires the same type for all operands and results}}
  "test.same_operand_and_result_type"(%t10, %t20) : (tensor<10xf32>, tensor<20xf32>) -> tensor<10xf32>
}

// -----

func @failedHasParent_wrong_parent() {
  "some.op"() ({
   // expected-error@+1 {{'test.child' op expects parent op 'test.parent'}}
    "test.child"() : () -> ()
  }) : () -> ()
}

// -----

func @failedSingleBlockImplicitTerminator_empty_block() {
   // expected-error@+1 {{'test.SingleBlockImplicitTerminator' op expects a non-empty block}}
  "test.SingleBlockImplicitTerminator"() ({
  ^entry:
  }) : () -> ()
}

// -----

func @failedSingleBlockImplicitTerminator_too_many_blocks() {
   // expected-error@+1 {{'test.SingleBlockImplicitTerminator' op expects region #0 to have 0 or 1 block}}
  "test.SingleBlockImplicitTerminator"() ({
  ^entry:
    "test.finish" () : () -> ()
  ^other:
    "test.finish" () : () -> ()
  }) : () -> ()
}

// -----

func @failedSingleBlockImplicitTerminator_missing_terminator() {
   // expected-error@+2 {{'test.SingleBlockImplicitTerminator' op expects regions to end with 'test.finish'}}
   // expected-note@+1 {{in custom textual format, the absence of terminator implies 'test.finish'}}
  "test.SingleBlockImplicitTerminator"() ({
  ^entry:
    "test.non_existent_op"() : () -> ()
  }) : () -> ()
}

// -----

// Test that operation with the SymbolTable Trait define a new symbol scope.
"test.symbol_scope"() ({
  func @foo() {
  }
  "test.finish" () : () -> ()
}) : () -> ()
func @foo() {
}

// -----

// Test that operation with the SymbolTable Trait fails with  too many blocks.
// expected-error@+1 {{Operations with a 'SymbolTable' must have exactly one block}}
"test.symbol_scope"() ({
  ^entry:
    "test.finish" () : () -> ()
  ^other:
    "test.finish" () : () -> ()
}) : () -> ()

// -----

func @failedMissingOperandSizeAttr(%arg: i32) {
  // expected-error @+1 {{requires 1D vector attribute 'operand_segment_sizes'}}
  "test.attr_sized_operands"(%arg, %arg, %arg, %arg) : (i32, i32, i32, i32) -> ()
}

// -----

func @failedOperandSizeAttrWrongType(%arg: i32) {
  // expected-error @+1 {{requires 1D vector attribute 'operand_segment_sizes'}}
  "test.attr_sized_operands"(%arg, %arg, %arg, %arg) {operand_segment_sizes = dense<[1, 1, 1, 1]>: tensor<4xi32>} : (i32, i32, i32, i32) -> ()
}

// -----

func @failedOperandSizeAttrWrongRank(%arg: i32) {
  // expected-error @+1 {{requires 1D vector attribute 'operand_segment_sizes'}}
  "test.attr_sized_operands"(%arg, %arg, %arg, %arg) {operand_segment_sizes = dense<[[1, 1], [1, 1]]>: vector<2x2xi32>} : (i32, i32, i32, i32) -> ()
}

// -----

func @failedOperandSizeAttrNegativeValue(%arg: i32) {
  // expected-error @+1 {{'operand_segment_sizes' attribute cannot have negative elements}}
  "test.attr_sized_operands"(%arg, %arg, %arg, %arg) {operand_segment_sizes = dense<[1, 1, -1, 1]>: vector<4xi32>} : (i32, i32, i32, i32) -> ()
}

// -----

func @failedOperandSizeAttrWrongTotalSize(%arg: i32) {
  // expected-error @+1 {{operand count (4) does not match with the total size (3) specified in attribute 'operand_segment_sizes'}}
  "test.attr_sized_operands"(%arg, %arg, %arg, %arg) {operand_segment_sizes = dense<[0, 1, 1, 1]>: vector<4xi32>} : (i32, i32, i32, i32) -> ()
}

// -----

func @failedOperandSizeAttrWrongCount(%arg: i32) {
  // expected-error @+1 {{'operand_segment_sizes' attribute for specifiying operand segments must have 4 elements}}
  "test.attr_sized_operands"(%arg, %arg, %arg, %arg) {operand_segment_sizes = dense<[2, 1, 1]>: vector<3xi32>} : (i32, i32, i32, i32) -> ()
}

// -----

func @succeededOperandSizeAttr(%arg: i32) {
  // CHECK: test.attr_sized_operands
  "test.attr_sized_operands"(%arg, %arg, %arg, %arg) {operand_segment_sizes = dense<[0, 2, 1, 1]>: vector<4xi32>} : (i32, i32, i32, i32) -> ()
  return
}

// -----

func @failedMissingResultSizeAttr() {
  // expected-error @+1 {{requires 1D vector attribute 'result_segment_sizes'}}
  %0:4 = "test.attr_sized_results"() : () -> (i32, i32, i32, i32)
}

// -----

func @failedResultSizeAttrWrongType() {
  // expected-error @+1 {{requires 1D vector attribute 'result_segment_sizes'}}
  %0:4 = "test.attr_sized_results"() {result_segment_sizes = dense<[1, 1, 1, 1]>: tensor<4xi32>} : () -> (i32, i32, i32, i32)
}

// -----

func @failedResultSizeAttrWrongRank() {
  // expected-error @+1 {{requires 1D vector attribute 'result_segment_sizes'}}
  %0:4 = "test.attr_sized_results"() {result_segment_sizes = dense<[[1, 1], [1, 1]]>: vector<2x2xi32>} : () -> (i32, i32, i32, i32)
}

// -----

func @failedResultSizeAttrNegativeValue() {
  // expected-error @+1 {{'result_segment_sizes' attribute cannot have negative elements}}
  %0:4 = "test.attr_sized_results"() {result_segment_sizes = dense<[1, 1, -1, 1]>: vector<4xi32>} : () -> (i32, i32, i32, i32)
}

// -----

func @failedResultSizeAttrWrongTotalSize() {
  // expected-error @+1 {{result count (4) does not match with the total size (3) specified in attribute 'result_segment_sizes'}}
  %0:4 = "test.attr_sized_results"() {result_segment_sizes = dense<[0, 1, 1, 1]>: vector<4xi32>} : () -> (i32, i32, i32, i32)
}

// -----

func @failedResultSizeAttrWrongCount() {
  // expected-error @+1 {{'result_segment_sizes' attribute for specifiying result segments must have 4 elements}}
  %0:4 = "test.attr_sized_results"() {result_segment_sizes = dense<[2, 1, 1]>: vector<3xi32>} : () -> (i32, i32, i32, i32)
}

// -----

func @succeededResultSizeAttr() {
  // CHECK: test.attr_sized_results
  %0:4 = "test.attr_sized_results"() {result_segment_sizes = dense<[0, 2, 1, 1]>: vector<4xi32>} : () -> (i32, i32, i32, i32)
  return
}
