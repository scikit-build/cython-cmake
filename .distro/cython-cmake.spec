Name:           cython-cmake
Version:        0.0.0
Release:        %autorelease
Summary:        CMake helpers for building Cython modules

License:        Apache-2.0
URL:            https://github.com/scikit-build/cython-cmake
Source:         %{pypi_source cython_cmake}
BuildArch:      noarch

BuildRequires:  python3-devel
# Testing dependences
BuildRequires:  cmake
BuildRequires:  gcc
BuildRequires:  g++
Requires:       cmake
Requires:       python3-devel
Requires:       python3dist(cython)

%global _description %{expand:
This provides helpers for using Cython. Use:

find_package(Cython MODULE REQUIRED VERSION 3.0)
include(UseCython)
}

%description %_description

CMake module files.

%package -n python3-cython-cmake
Summary:        %{summary}
Requires:       cython-cmake = %{version}-%{release}
%description -n python3-cython-cmake %_description

Python package.


%prep
%autosetup -n cython_cmake-%{version}


%generate_buildrequires
%pyproject_buildrequires -x test


%build
%pyproject_wheel


%install
%pyproject_install
%pyproject_save_files -l cython_cmake
# Move the actual CMake modules to /usr/share/cmake
mkdir -p %{buildroot}%{_datadir}/cmake/Modules
mv %{buildroot}%{python3_sitelib}/cython_cmake/cmake/*.cmake %{buildroot}%{_datadir}/cmake/Modules/
ln -rs %{buildroot}%{_datadir}/cmake/Modules/*.cmake %{buildroot}%{python3_sitelib}/cython_cmake/cmake/


%check
%pyproject_check_import
%pytest


%files
%{_datadir}/cmake/Modules/*.cmake
%license LICENSE
%doc README.md

%files -n python3-cython-cmake -f %{pyproject_files}
%{_bindir}/cython-cmake


%changelog
%autochangelog
