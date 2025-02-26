// RUN: mlir-opt -convert-std-to-llvm %s | FileCheck %s
// RUN: mlir-opt -convert-std-to-llvm -convert-std-to-llvm-use-alloca=1 %s | FileCheck %s --check-prefix=ALLOCA

// CHECK-LABEL: func @check_arguments(%arg0: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">, %arg1: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">, %arg2: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">)
func @check_arguments(%static: memref<10x20xf32>, %dynamic : memref<?x?xf32>, %mixed : memref<10x?xf32>) {
  return
}

//   CHECK-LABEL: func @check_strided_memref_arguments(
// CHECK-COUNT-3:   !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
func @check_strided_memref_arguments(%static: memref<10x20xf32, (i,j)->(20 * i + j + 1)>,
                                     %dynamic : memref<?x?xf32, (i,j)[M]->(M * i + j + 1)>,
                                     %mixed : memref<10x?xf32, (i,j)[M]->(M * i + j + 1)>) {
  return
}

// CHECK-LABEL: func @check_static_return(%arg0: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">) -> !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> {
func @check_static_return(%static : memref<32x18xf32>) -> memref<32x18xf32> {
// CHECK:  llvm.return %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  return %static : memref<32x18xf32>
}

// CHECK-LABEL: func @zero_d_alloc() -> !llvm<"{ float*, float*, i64 }"> {
// ALLOCA-LABEL: func @zero_d_alloc() -> !llvm<"{ float*, float*, i64 }"> {
func @zero_d_alloc() -> memref<f32> {
// CHECK-NEXT:  llvm.mlir.constant(1 : index) : !llvm.i64
// CHECK-NEXT:  %[[null:.*]] = llvm.mlir.null : !llvm<"float*">
// CHECK-NEXT:  %[[one:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
// CHECK-NEXT:  %[[gep:.*]] = llvm.getelementptr %[[null]][%[[one]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
// CHECK-NEXT:  %[[sizeof:.*]] = llvm.ptrtoint %[[gep]] : !llvm<"float*"> to !llvm.i64
// CHECK-NEXT:  llvm.mul %{{.*}}, %[[sizeof]] : !llvm.i64
// CHECK-NEXT:  llvm.call @malloc(%{{.*}}) : (!llvm.i64) -> !llvm<"i8*">
// CHECK-NEXT:  %[[ptr:.*]] = llvm.bitcast %{{.*}} : !llvm<"i8*"> to !llvm<"float*">
// CHECK-NEXT:  llvm.mlir.undef : !llvm<"{ float*, float*, i64 }">
// CHECK-NEXT:  llvm.insertvalue %[[ptr]], %{{.*}}[0] : !llvm<"{ float*, float*, i64 }">
// CHECK-NEXT:  llvm.insertvalue %[[ptr]], %{{.*}}[1] : !llvm<"{ float*, float*, i64 }">
// CHECK-NEXT:  %[[c0:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
// CHECK-NEXT:  llvm.insertvalue %[[c0]], %{{.*}}[2] : !llvm<"{ float*, float*, i64 }">

// ALLOCA-NOT: malloc
//     ALLOCA: alloca
// ALLOCA-NOT: malloc
  %0 = alloc() : memref<f32>
  return %0 : memref<f32>
}

// CHECK-LABEL: func @zero_d_dealloc(%{{.*}}: !llvm<"{ float*, float*, i64 }*">) {
func @zero_d_dealloc(%arg0: memref<f32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64 }*">
// CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][0] : !llvm<"{ float*, float*, i64 }">
// CHECK-NEXT:  %[[bc:.*]] = llvm.bitcast %[[ptr]] : !llvm<"float*"> to !llvm<"i8*">
// CHECK-NEXT:  llvm.call @free(%[[bc]]) : (!llvm<"i8*">) -> ()
  dealloc %arg0 : memref<f32>
  return
}

// CHECK-LABEL: func @aligned_1d_alloc(
func @aligned_1d_alloc() -> memref<42xf32> {
// CHECK-NEXT:  llvm.mlir.constant(42 : index) : !llvm.i64
// CHECK-NEXT:  %[[null:.*]] = llvm.mlir.null : !llvm<"float*">
// CHECK-NEXT:  %[[one:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
// CHECK-NEXT:  %[[gep:.*]] = llvm.getelementptr %[[null]][%[[one]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
// CHECK-NEXT:  %[[sizeof:.*]] = llvm.ptrtoint %[[gep]] : !llvm<"float*"> to !llvm.i64
// CHECK-NEXT:  llvm.mul %{{.*}}, %[[sizeof]] : !llvm.i64
// CHECK-NEXT:  %[[alignment:.*]] = llvm.mlir.constant(8 : index) : !llvm.i64
// CHECK-NEXT:  %[[alignmentMinus1:.*]] = llvm.add {{.*}}, %[[alignment]] : !llvm.i64
// CHECK-NEXT:  %[[allocsize:.*]] = llvm.sub %[[alignmentMinus1]], %[[one]] : !llvm.i64
// CHECK-NEXT:  %[[allocated:.*]] = llvm.call @malloc(%[[allocsize]]) : (!llvm.i64) -> !llvm<"i8*">
// CHECK-NEXT:  %[[ptr:.*]] = llvm.bitcast %{{.*}} : !llvm<"i8*"> to !llvm<"float*">
// CHECK-NEXT:  llvm.mlir.undef : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
// CHECK-NEXT:  llvm.insertvalue %[[ptr]], %{{.*}}[0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
// CHECK-NEXT:  %[[allocatedAsInt:.*]] = llvm.ptrtoint %[[allocated]] : !llvm<"i8*"> to !llvm.i64
// CHECK-NEXT:  %[[alignAdj1:.*]] = llvm.urem %[[allocatedAsInt]], %[[alignment]] : !llvm.i64
// CHECK-NEXT:  %[[alignAdj2:.*]] = llvm.sub %[[alignment]], %[[alignAdj1]] : !llvm.i64
// CHECK-NEXT:  %[[alignAdj3:.*]] = llvm.urem %[[alignAdj2]], %[[alignment]] : !llvm.i64
// CHECK-NEXT:  %[[aligned:.*]] = llvm.getelementptr %9[%[[alignAdj3]]] : (!llvm<"i8*">, !llvm.i64) -> !llvm<"i8*">
// CHECK-NEXT:  %[[alignedBitCast:.*]] = llvm.bitcast %[[aligned]] : !llvm<"i8*"> to !llvm<"float*">
// CHECK-NEXT:  llvm.insertvalue %[[alignedBitCast]], %{{.*}}[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
// CHECK-NEXT:  %[[c0:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
// CHECK-NEXT:  llvm.insertvalue %[[c0]], %{{.*}}[2] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
  %0 = alloc() {alignment = 8} : memref<42xf32>
  return %0 : memref<42xf32>
}

// CHECK-LABEL: func @mixed_alloc(
//       CHECK:   %[[M:.*]]: !llvm.i64, %[[N:.*]]: !llvm.i64) -> !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }"> {
func @mixed_alloc(%arg0: index, %arg1: index) -> memref<?x42x?xf32> {
//  CHECK-NEXT:  %[[c42:.*]] = llvm.mlir.constant(42 : index) : !llvm.i64
//  CHECK-NEXT:  llvm.mul %[[M]], %[[c42]] : !llvm.i64
//  CHECK-NEXT:  %[[sz:.*]] = llvm.mul %{{.*}}, %[[N]] : !llvm.i64
//  CHECK-NEXT:  %[[null:.*]] = llvm.mlir.null : !llvm<"float*">
//  CHECK-NEXT:  %[[one:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[gep:.*]] = llvm.getelementptr %[[null]][%[[one]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
//  CHECK-NEXT:  %[[sizeof:.*]] = llvm.ptrtoint %[[gep]] : !llvm<"float*"> to !llvm.i64
//  CHECK-NEXT:  %[[sz_bytes:.*]] = llvm.mul %[[sz]], %[[sizeof]] : !llvm.i64
//  CHECK-NEXT:  llvm.call @malloc(%[[sz_bytes]]) : (!llvm.i64) -> !llvm<"i8*">
//  CHECK-NEXT:  llvm.bitcast %{{.*}} : !llvm<"i8*"> to !llvm<"float*">
//  CHECK-NEXT:  llvm.mlir.undef : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %{{.*}}, %{{.*}}[0] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %{{.*}}, %{{.*}}[1] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
//  CHECK-NEXT:  llvm.insertvalue %[[off]], %{{.*}}[2] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  %[[st2:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[st1:.*]] = llvm.mul %{{.*}}, %[[c42]] : !llvm.i64
//  CHECK-NEXT:  %[[st0:.*]] = llvm.mul %{{.*}}, %[[M]] : !llvm.i64
//  CHECK-NEXT:  llvm.insertvalue %[[M]], %{{.*}}[3, 0] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %[[st0]], %{{.*}}[4, 0] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %[[c42]], %{{.*}}[3, 1] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %[[st1]], %{{.*}}[4, 1] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %[[N]], %{{.*}}[3, 2] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %[[st2]], %{{.*}}[4, 2] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
  %0 = alloc(%arg0, %arg1) : memref<?x42x?xf32>
//  CHECK-NEXT:  llvm.return %{{.*}} : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
  return %0 : memref<?x42x?xf32>
}

// CHECK-LABEL: func @mixed_dealloc(%arg0: !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }*">) {
func @mixed_dealloc(%arg0: memref<?x42x?xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }*">
// CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][0] : !llvm<"{ float*, float*, i64, [3 x i64], [3 x i64] }">
// CHECK-NEXT:  %[[ptri8:.*]] = llvm.bitcast %[[ptr]] : !llvm<"float*"> to !llvm<"i8*">
// CHECK-NEXT:  llvm.call @free(%[[ptri8]]) : (!llvm<"i8*">) -> ()
  dealloc %arg0 : memref<?x42x?xf32>
// CHECK-NEXT:  llvm.return
  return
}

// CHECK-LABEL: func @dynamic_alloc(
//       CHECK:   %[[M:.*]]: !llvm.i64, %[[N:.*]]: !llvm.i64) -> !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> {
func @dynamic_alloc(%arg0: index, %arg1: index) -> memref<?x?xf32> {
//  CHECK-NEXT:  %[[sz:.*]] = llvm.mul %[[M]], %[[N]] : !llvm.i64
//  CHECK-NEXT:  %[[null:.*]] = llvm.mlir.null : !llvm<"float*">
//  CHECK-NEXT:  %[[one:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[gep:.*]] = llvm.getelementptr %[[null]][%[[one]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
//  CHECK-NEXT:  %[[sizeof:.*]] = llvm.ptrtoint %[[gep]] : !llvm<"float*"> to !llvm.i64
//  CHECK-NEXT:  %[[sz_bytes:.*]] = llvm.mul %[[sz]], %[[sizeof]] : !llvm.i64
//  CHECK-NEXT:  llvm.call @malloc(%[[sz_bytes]]) : (!llvm.i64) -> !llvm<"i8*">
//  CHECK-NEXT:  llvm.bitcast %{{.*}} : !llvm<"i8*"> to !llvm<"float*">
//  CHECK-NEXT:  llvm.mlir.undef : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %{{.*}}, %{{.*}}[0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %{{.*}}, %{{.*}}[1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
//  CHECK-NEXT:  llvm.insertvalue %[[off]], %{{.*}}[2] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[st1:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[st0:.*]] = llvm.mul %{{.*}}, %[[M]] : !llvm.i64
//  CHECK-NEXT:  llvm.insertvalue %[[M]], %{{.*}}[3, 0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %[[st0]], %{{.*}}[4, 0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %[[N]], %{{.*}}[3, 1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  llvm.insertvalue %[[st1]], %{{.*}}[4, 1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  %0 = alloc(%arg0, %arg1) : memref<?x?xf32>
//  CHECK-NEXT:  llvm.return %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  return %0 : memref<?x?xf32>
}

// CHECK-LABEL: func @dynamic_dealloc(%arg0: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">) {
func @dynamic_dealloc(%arg0: memref<?x?xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
// CHECK-NEXT:  %[[ptri8:.*]] = llvm.bitcast %[[ptr]] : !llvm<"float*"> to !llvm<"i8*">
// CHECK-NEXT:  llvm.call @free(%[[ptri8]]) : (!llvm<"i8*">) -> ()
  dealloc %arg0 : memref<?x?xf32>
  return
}

// CHECK-LABEL: func @static_alloc() -> !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> {
func @static_alloc() -> memref<32x18xf32> {
// CHECK-NEXT:  %[[sz1:.*]] = llvm.mlir.constant(32 : index) : !llvm.i64
// CHECK-NEXT:  %[[sz2:.*]] = llvm.mlir.constant(18 : index) : !llvm.i64
// CHECK-NEXT:  %[[num_elems:.*]] = llvm.mul %0, %1 : !llvm.i64
// CHECK-NEXT:  %[[null:.*]] = llvm.mlir.null : !llvm<"float*">
// CHECK-NEXT:  %[[one:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
// CHECK-NEXT:  %[[gep:.*]] = llvm.getelementptr %[[null]][%[[one]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
//  CHECK-NEXT:  %[[sizeof:.*]] = llvm.ptrtoint %[[gep]] : !llvm<"float*"> to !llvm.i64
// CHECK-NEXT:  %[[bytes:.*]] = llvm.mul %[[num_elems]], %[[sizeof]] : !llvm.i64
// CHECK-NEXT:  %[[allocated:.*]] = llvm.call @malloc(%[[bytes]]) : (!llvm.i64) -> !llvm<"i8*">
// CHECK-NEXT:  llvm.bitcast %[[allocated]] : !llvm<"i8*"> to !llvm<"float*">
 %0 = alloc() : memref<32x18xf32>
 return %0 : memref<32x18xf32>
}

// CHECK-LABEL: func @static_dealloc(%{{.*}}: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">) {
func @static_dealloc(%static: memref<10x8xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
// CHECK-NEXT:  %[[bc:.*]] = llvm.bitcast %[[ptr]] : !llvm<"float*"> to !llvm<"i8*">
// CHECK-NEXT:  llvm.call @free(%[[bc]]) : (!llvm<"i8*">) -> ()
  dealloc %static : memref<10x8xf32>
  return
}

// CHECK-LABEL: func @zero_d_load(%{{.*}}: !llvm<"{ float*, float*, i64 }*">) -> !llvm.float {
func @zero_d_load(%arg0: memref<f32>) -> f32 {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64 }*">
// CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][1] : !llvm<"{ float*, float*, i64 }">
// CHECK-NEXT:  %[[c0:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
// CHECK-NEXT:  %[[addr:.*]] = llvm.getelementptr %[[ptr]][%[[c0]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
// CHECK-NEXT:  %{{.*}} = llvm.load %[[addr]] : !llvm<"float*">
  %0 = load %arg0[] : memref<f32>
  return %0 : f32
}

// CHECK-LABEL: func @static_load(
//       CHECK:   %[[A:.*]]: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">, %[[I:.*]]: !llvm.i64, %[[J:.*]]: !llvm.i64
func @static_load(%static : memref<10x42xf32>, %i : index, %j : index) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
//  CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
//  CHECK-NEXT:  %[[st0:.*]] = llvm.mlir.constant(42 : index) : !llvm.i64
//  CHECK-NEXT:  %[[offI:.*]] = llvm.mul %[[I]], %[[st0]] : !llvm.i64
//  CHECK-NEXT:  %[[off0:.*]] = llvm.add %[[off]], %[[offI]] : !llvm.i64
//  CHECK-NEXT:  %[[st1:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[offJ:.*]] = llvm.mul %[[J]], %[[st1]] : !llvm.i64
//  CHECK-NEXT:  %[[off1:.*]] = llvm.add %[[off0]], %[[offJ]] : !llvm.i64
//  CHECK-NEXT:  %[[addr:.*]] = llvm.getelementptr %[[ptr]][%[[off1]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
// CHECK-NEXT:  llvm.load %[[addr]] : !llvm<"float*">
  %0 = load %static[%i, %j] : memref<10x42xf32>
  return
}

// CHECK-LABEL: func @mixed_load(
//       CHECK:   %[[A:.*]]: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">, %[[I:.*]]: !llvm.i64, %[[J:.*]]: !llvm.i64
func @mixed_load(%mixed : memref<42x?xf32>, %i : index, %j : index) {
//  CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
//  CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
//  CHECK-NEXT:  %[[st0:.*]] = llvm.extractvalue %[[ld]][4, 0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[offI:.*]] = llvm.mul %[[I]], %[[st0]] : !llvm.i64
//  CHECK-NEXT:  %[[off0:.*]] = llvm.add %[[off]], %[[offI]] : !llvm.i64
//  CHECK-NEXT:  %[[st1:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[offJ:.*]] = llvm.mul %[[J]], %[[st1]] : !llvm.i64
//  CHECK-NEXT:  %[[off1:.*]] = llvm.add %[[off0]], %[[offJ]] : !llvm.i64
//  CHECK-NEXT:  %[[addr:.*]] = llvm.getelementptr %[[ptr]][%[[off1]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
//  CHECK-NEXT:  llvm.load %[[addr]] : !llvm<"float*">
  %0 = load %mixed[%i, %j] : memref<42x?xf32>
  return
}

// CHECK-LABEL: func @dynamic_load(
//       CHECK:   %[[A:.*]]: !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">, %[[I:.*]]: !llvm.i64, %[[J:.*]]: !llvm.i64
func @dynamic_load(%dynamic : memref<?x?xf32>, %i : index, %j : index) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
//  CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
//  CHECK-NEXT:  %[[st0:.*]] = llvm.extractvalue %[[ld]][4, 0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[offI:.*]] = llvm.mul %[[I]], %[[st0]] : !llvm.i64
//  CHECK-NEXT:  %[[off0:.*]] = llvm.add %[[off]], %[[offI]] : !llvm.i64
//  CHECK-NEXT:  %[[st1:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[offJ:.*]] = llvm.mul %[[J]], %[[st1]] : !llvm.i64
//  CHECK-NEXT:  %[[off1:.*]] = llvm.add %[[off0]], %[[offJ]] : !llvm.i64
//  CHECK-NEXT:  %[[addr:.*]] = llvm.getelementptr %[[ptr]][%[[off1]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
//  CHECK-NEXT:  llvm.load %[[addr]] : !llvm<"float*">
  %0 = load %dynamic[%i, %j] : memref<?x?xf32>
  return
}

// CHECK-LABEL: func @zero_d_store(%arg0: !llvm<"{ float*, float*, i64 }*">, %arg1: !llvm.float) {
func @zero_d_store(%arg0: memref<f32>, %arg1: f32) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64 }*">
// CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][1] : !llvm<"{ float*, float*, i64 }">
// CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
// CHECK-NEXT:  %[[addr:.*]] = llvm.getelementptr %[[ptr]][%[[off]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
// CHECK-NEXT:  llvm.store %arg1, %[[addr]] : !llvm<"float*">
  store %arg1, %arg0[] : memref<f32>
  return
}

// CHECK-LABEL: func @static_store
func @static_store(%static : memref<10x42xf32>, %i : index, %j : index, %val : f32) {
//  CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
//  CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
//  CHECK-NEXT:  %[[st0:.*]] = llvm.mlir.constant(42 : index) : !llvm.i64
//  CHECK-NEXT:  %[[offI:.*]] = llvm.mul %[[I]], %[[st0]] : !llvm.i64
//  CHECK-NEXT:  %[[off0:.*]] = llvm.add %[[off]], %[[offI]] : !llvm.i64
//  CHECK-NEXT:  %[[st1:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[offJ:.*]] = llvm.mul %[[J]], %[[st1]] : !llvm.i64
//  CHECK-NEXT:  %[[off1:.*]] = llvm.add %[[off0]], %[[offJ]] : !llvm.i64
//  CHECK-NEXT:  %[[addr:.*]] = llvm.getelementptr %[[ptr]][%[[off1]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
//  CHECK-NEXT:  llvm.store %arg3, %[[addr]] : !llvm<"float*">
  store %val, %static[%i, %j] : memref<10x42xf32>
  return
}

// CHECK-LABEL: func @dynamic_store
func @dynamic_store(%dynamic : memref<?x?xf32>, %i : index, %j : index, %val : f32) {
//  CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
//  CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
//  CHECK-NEXT:  %[[st0:.*]] = llvm.extractvalue %[[ld]][4, 0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[offI:.*]] = llvm.mul %[[I]], %[[st0]] : !llvm.i64
//  CHECK-NEXT:  %[[off0:.*]] = llvm.add %[[off]], %[[offI]] : !llvm.i64
//  CHECK-NEXT:  %[[st1:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[offJ:.*]] = llvm.mul %[[J]], %[[st1]] : !llvm.i64
//  CHECK-NEXT:  %[[off1:.*]] = llvm.add %[[off0]], %[[offJ]] : !llvm.i64
//  CHECK-NEXT:  %[[addr:.*]] = llvm.getelementptr %[[ptr]][%[[off1]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
//  CHECK-NEXT:  llvm.store %arg3, %[[addr]] : !llvm<"float*">
  store %val, %dynamic[%i, %j] : memref<?x?xf32>
  return
}

// CHECK-LABEL: func @mixed_store
func @mixed_store(%mixed : memref<42x?xf32>, %i : index, %j : index, %val : f32) {
//  CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
//  CHECK-NEXT:  %[[ptr:.*]] = llvm.extractvalue %[[ld]][1] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[off:.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
//  CHECK-NEXT:  %[[st0:.*]] = llvm.extractvalue %[[ld]][4, 0] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
//  CHECK-NEXT:  %[[offI:.*]] = llvm.mul %[[I]], %[[st0]] : !llvm.i64
//  CHECK-NEXT:  %[[off0:.*]] = llvm.add %[[off]], %[[offI]] : !llvm.i64
//  CHECK-NEXT:  %[[st1:.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
//  CHECK-NEXT:  %[[offJ:.*]] = llvm.mul %[[J]], %[[st1]] : !llvm.i64
//  CHECK-NEXT:  %[[off1:.*]] = llvm.add %[[off0]], %[[offJ]] : !llvm.i64
//  CHECK-NEXT:  %[[addr:.*]] = llvm.getelementptr %[[ptr]][%[[off1]]] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
//  CHECK-NEXT:  llvm.store %arg3, %[[addr]] : !llvm<"float*">
  store %val, %mixed[%i, %j] : memref<42x?xf32>
  return
}

// CHECK-LABEL: func @memref_cast_static_to_dynamic
func @memref_cast_static_to_dynamic(%static : memref<10x42xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  llvm.bitcast %[[ld]] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> to !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  %0 = memref_cast %static : memref<10x42xf32> to memref<?x?xf32>
  return
}

// CHECK-LABEL: func @memref_cast_static_to_mixed
func @memref_cast_static_to_mixed(%static : memref<10x42xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  llvm.bitcast %[[ld]] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> to !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  %0 = memref_cast %static : memref<10x42xf32> to memref<?x42xf32>
  return
}

// CHECK-LABEL: func @memref_cast_dynamic_to_static
func @memref_cast_dynamic_to_static(%dynamic : memref<?x?xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  llvm.bitcast %[[ld]] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> to !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  %0 = memref_cast %dynamic : memref<?x?xf32> to memref<10x12xf32>
  return
}

// CHECK-LABEL: func @memref_cast_dynamic_to_mixed
func @memref_cast_dynamic_to_mixed(%dynamic : memref<?x?xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  llvm.bitcast %[[ld]] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> to !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  %0 = memref_cast %dynamic : memref<?x?xf32> to memref<?x12xf32>
  return
}

// CHECK-LABEL: func @memref_cast_mixed_to_dynamic
func @memref_cast_mixed_to_dynamic(%mixed : memref<42x?xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  llvm.bitcast %[[ld]] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> to !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  %0 = memref_cast %mixed : memref<42x?xf32> to memref<?x?xf32>
  return
}

// CHECK-LABEL: func @memref_cast_mixed_to_static
func @memref_cast_mixed_to_static(%mixed : memref<42x?xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  llvm.bitcast %[[ld]] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> to !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  %0 = memref_cast %mixed : memref<42x?xf32> to memref<42x1xf32>
  return
}

// CHECK-LABEL: func @memref_cast_mixed_to_mixed
func @memref_cast_mixed_to_mixed(%mixed : memref<42x?xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }*">
// CHECK-NEXT:  llvm.bitcast %[[ld]] : !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }"> to !llvm<"{ float*, float*, i64, [2 x i64], [2 x i64] }">
  %0 = memref_cast %mixed : memref<42x?xf32> to memref<?x1xf32>
  return
}

// CHECK-LABEL: func @mixed_memref_dim(%arg0: !llvm<"{ float*, float*, i64, [5 x i64], [5 x i64] }*">) {
func @mixed_memref_dim(%mixed : memref<42x?x?x13x?xf32>) {
//  CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [5 x i64], [5 x i64] }*">
//  CHECK-NEXT:  llvm.mlir.constant(42 : index) : !llvm.i64
  %0 = dim %mixed, 0 : memref<42x?x?x13x?xf32>
//  CHECK-NEXT:  llvm.extractvalue %[[ld]][3, 1] : !llvm<"{ float*, float*, i64, [5 x i64], [5 x i64] }">
  %1 = dim %mixed, 1 : memref<42x?x?x13x?xf32>
//  CHECK-NEXT:  llvm.extractvalue %[[ld]][3, 2] : !llvm<"{ float*, float*, i64, [5 x i64], [5 x i64] }">
  %2 = dim %mixed, 2 : memref<42x?x?x13x?xf32>
//  CHECK-NEXT:  llvm.mlir.constant(13 : index) : !llvm.i64
  %3 = dim %mixed, 3 : memref<42x?x?x13x?xf32>
//  CHECK-NEXT:  llvm.extractvalue %[[ld]][3, 4] : !llvm<"{ float*, float*, i64, [5 x i64], [5 x i64] }">
  %4 = dim %mixed, 4 : memref<42x?x?x13x?xf32>
  return
}

// CHECK-LABEL: func @static_memref_dim(%arg0: !llvm<"{ float*, float*, i64, [5 x i64], [5 x i64] }*">) {
func @static_memref_dim(%static : memref<42x32x15x13x27xf32>) {
// CHECK-NEXT:  %[[ld:.*]] = llvm.load %{{.*}} : !llvm<"{ float*, float*, i64, [5 x i64], [5 x i64] }*">
// CHECK-NEXT:  llvm.mlir.constant(42 : index) : !llvm.i64
  %0 = dim %static, 0 : memref<42x32x15x13x27xf32>
// CHECK-NEXT:  llvm.mlir.constant(32 : index) : !llvm.i64
  %1 = dim %static, 1 : memref<42x32x15x13x27xf32>
// CHECK-NEXT:  llvm.mlir.constant(15 : index) : !llvm.i64
  %2 = dim %static, 2 : memref<42x32x15x13x27xf32>
// CHECK-NEXT:  llvm.mlir.constant(13 : index) : !llvm.i64
  %3 = dim %static, 3 : memref<42x32x15x13x27xf32>
// CHECK-NEXT:  llvm.mlir.constant(27 : index) : !llvm.i64
  %4 = dim %static, 4 : memref<42x32x15x13x27xf32>
  return
}

