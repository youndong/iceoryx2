// Copyright (c) 2025 Contributors to the Eclipse Foundation
//
// See the NOTICE file(s) distributed with this work for additional
// information regarding copyright ownership.
//
// This program and the accompanying materials are made available under the
// terms of the Apache Software License 2.0 which is available at
// https://www.apache.org/licenses/LICENSE-2.0, or the MIT license
// which is available at https://opensource.org/licenses/MIT.
//
// SPDX-License-Identifier: Apache-2.0 OR MIT

use pyo3::prelude::*;

#[pyclass(eq, eq_int)]
#[derive(PartialEq, Clone, Debug)]
/// Describes generically an `AllocationStrategy`, meaning how the memory is increased when the
/// available memory is insufficient.
pub enum AllocationStrategy {
    /// Increases the memory so that it perfectly fits the new size requirements. This may lead
    /// to a lot of reallocations but has the benefit that no byte is wasted.
    BestFit,
    /// Increases the memory by rounding the increased memory size up to the next power of two.
    /// Reduces reallocations a lot at the cost of increased memory usage.
    PowerOfTwo,
    /// The memory is not increased. This may lead to an out-of-memory error when allocating.
    Static,
}

#[pymethods]
impl AllocationStrategy {
    pub fn __str__(&self) -> String {
        format!("{self:?}")
    }
}

impl From<iceoryx2::prelude::AllocationStrategy> for AllocationStrategy {
    fn from(value: iceoryx2::prelude::AllocationStrategy) -> Self {
        match value {
            iceoryx2::prelude::AllocationStrategy::Static => AllocationStrategy::Static,
            iceoryx2::prelude::AllocationStrategy::BestFit => AllocationStrategy::BestFit,
            iceoryx2::prelude::AllocationStrategy::PowerOfTwo => AllocationStrategy::PowerOfTwo,
        }
    }
}

impl From<AllocationStrategy> for iceoryx2::prelude::AllocationStrategy {
    fn from(value: AllocationStrategy) -> Self {
        match value {
            AllocationStrategy::Static => iceoryx2::prelude::AllocationStrategy::Static,
            AllocationStrategy::BestFit => iceoryx2::prelude::AllocationStrategy::BestFit,
            AllocationStrategy::PowerOfTwo => iceoryx2::prelude::AllocationStrategy::PowerOfTwo,
        }
    }
}
