# Main package is arched in order to run tests on all arches
%global debug_package %{nil}

Name:           python-cython-cmake
Version:        0.0.0
Release:        %autorelease
Summary:        CMake helpers for building Cython modules

License:        Apache-2.0
URL:            https://github.com/scikit-build/cython-cmake
Source:         %{pypi_source cython_cmake}

BuildRequires:  python3-devel
# Testing dependences
BuildRequires:  cmake
BuildRequires:  gcc
BuildRequires:  g++

%global _description %{expand:
This provides helpers for using Cython. Use

find_package(Cython MODULE REQUIRED VERSION 3.0)
include(UseCython)
}

%description %_description

%package -n python3-cython-cmake
Summary:        %{summary}
Requires:       cmake
Requires:       python3-devel
BuildArch:      noarch
%description -n python3-cython-cmake %_description


%prep
%autosetup -n cython_cmake-%{version}


%generate_buildrequires
%pyproject_buildrequires -x test


%build
%pyproject_wheel


%install
%pyproject_install
%pyproject_save_files -l cython_cmake


%check
%pyproject_check_import
%pytest


%files -n python3-cython-cmake -f %{pyproject_files}
%{_bindir}/cython-cmake
%doc README.md


%changelog
%autochangelog
