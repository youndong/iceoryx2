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

#[pyclass(eq)]
#[derive(PartialEq, Eq)]
/// The system-wide unique id of a `Client`.
pub struct UniqueClientId(pub(crate) iceoryx2::port::port_identifiers::UniqueClientId);

#[pymethods]
impl UniqueClientId {
    #[getter]
    /// Returns the underlying raw value of the ID
    pub fn value(&self) -> u128 {
        self.0.value()
    }
}
