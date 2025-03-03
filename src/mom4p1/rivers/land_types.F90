!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!                                                                   !!
!!                   GNU General Public License                      !!
!!                                                                   !!
!! This file is part of the Flexible Modeling System (FMS).          !!
!!                                                                   !!
!! FMS is free software; you can redistribute it and/or modify       !!
!! it and are expected to follow the terms of the GNU General Public !!
!! License as published by the Free Software Foundation.             !!
!!                                                                   !!
!! FMS is distributed in the hope that it will be useful,            !!
!! but WITHOUT ANY WARRANTY; without even the implied warranty of    !!
!! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the     !!
!! GNU General Public License for more details.                      !!
!!                                                                   !!
!! You should have received a copy of the GNU General Public License !!
!! along with FMS; if not, write to:                                 !!
!!          Free Software Foundation, Inc.                           !!
!!          59 Temple Place, Suite 330                               !!
!!          Boston, MA  02111-1307  USA                              !!
!! or see:                                                           !!
!!          http://www.gnu.org/licenses/gpl.txt                      !!
!!                                                                   !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ============================================================================
! 
! ============================================================================
module land_types_mod

! <DESCRIPTION>
!   This module defines two derived types. atmos_land_boundary_type represents
!   data passed from the atmosphere to the surface and the derivatives of the
!   fluxes. Data describing the land is land_data_type. This module contains
!   routines for initializing land type data and allocating and deallocating
!   data for the specified domain and number of tiles.
! </DESCRIPTION>

  use mpp_domains_mod, only : domain2d, mpp_get_compute_domain
  use fms_mod, only : write_version_number

implicit none
private

! ==== public interfaces =====================================================
public :: atmos_land_boundary_type
public :: land_data_type

public :: allocate_boundary_data
public :: deallocate_boundary_data
! ==== end of public interfaces ==============================================

type :: atmos_land_boundary_type

!   <DATA NAME="runoff" UNITS="kg/m2/s" TYPE="real, pointer" DIM="3">
!     runoff from Noah land model
!   </DATA>

!   <DATA NAME="drainage" UNITS="kg/m2/s" TYPE="real, pointer" DIM="3">
!     subsurface runoff from Noah land model
!   </DATA>

   ! data passed from the atmosphere to the surface
   real, dimension(:,:,:), pointer :: &
        runoff =>NULL(),   &
        drainage =>NULL()

   real, dimension(:,:,:,:), pointer :: tr_flux => NULL()
   real, dimension(:,:,:,:), pointer :: dfdtr   => NULL()
   real, dimension(:,:,:), pointer :: &
        t_flux =>NULL(),  &
        q_flux =>NULL(),  &
        lw_flux =>NULL(), &
        lwdn_flux =>NULL(), &
        sw_flux =>NULL(), &
        sw_flux_down_vis_dir =>NULL(), &
        sw_flux_down_total_dir =>NULL(), &
        sw_flux_down_vis_dif =>NULL(), &
        sw_flux_down_total_dif =>NULL(), &
        lprec =>NULL(),   &
        fprec =>NULL(),   &
        tprec =>NULL()
   ! derivatives of the fluxes
   real, dimension(:,:,:), pointer :: &
        dhdt =>NULL(),    &
        dedt =>NULL(),    &
        dedq =>NULL(),    &
        drdt =>NULL()
   real, dimension(:,:,:), pointer :: &
        cd_m => NULL(),      &   ! drag coefficient for momentum, dimensionless
        cd_t => NULL(),      &   ! drag coefficient for tracers, dimensionless
        ustar => NULL(),     &   ! turbulent wind scale, m/s
        bstar => NULL(),     &   ! turbulent bouyancy scale, m/s
        wind => NULL(),      &   ! abs wind speed at the bottom of the atmos, m/s
        z_bot => NULL(),     &   ! height of the bottom atmos. layer above surface, m
        drag_q =>NULL(),  &
        p_surf =>NULL()

   real, dimension(:,:,:), pointer :: &
        data =>NULL() ! collective field for "named" fields above

   integer :: xtype             !REGRID, REDIST or DIRECT

end type atmos_land_boundary_type

type :: land_data_type

!   <DATA NAME="domain" TYPE="domain2d" DIM="2">
!     The computational domain
!   </DATA>

   type(domain2d) :: domain  ! our computation domain

!   <DATA NAME="tile_size" TYPE="real, pointer" DIM="3">
!     Fractional coverage of cell by tile, dimensionless
!   </DATA>

   real, pointer, dimension(:,:,:)   :: &  ! (lon, lat, tile)
        tile_size =>NULL() ! fractional coverage of cell by tile, dimensionless

!   <DATA NAME="discharge_runoff" UNITS="kg/m2/s" TYPE="real, pointer" DIM="2">
!     Outflow of fresh water from river mouths into the ocean (per unit area
!     of the ocean part of the grid cell)
!   </DATA>


!   <DATA NAME="discharge_drainage" UNITS="kg/m2/s" TYPE="real, pointer" DIM="2">
!     Snow analogue of discharge
!   </DATA>

   real, pointer, dimension(:,:) :: discharge_runoff    => NULL(), & ! flux from surface drainage network out of land model
                                    discharge_drainage  => NULL()

   real, pointer, dimension(:,:,:) ::  t_ca                => NULL(), & 
                                    	 t_surf              => NULL(), & ! ground surface temperature, degK
       		                          	 albedo              => NULL(),          & ! snow-adjusted land albedo
       		                          	 albedo_vis_dir      => NULL(),  & ! albedo for direct visible-band radiation
       		                          	 albedo_nir_dir      => NULL(),  & ! albedo for direct nir-band radiation
       		                          	 albedo_vis_dif      => NULL(),  & ! albedo for diffuse visible-band radiation
       		                          	 albedo_nir_dif      => NULL(),  & ! albedo for diffuse nir-band radiation
       		                          	 rough_mom           => NULL(),       & ! momentum roughness length, m
       		                          	 rough_heat          => NULL(),      & ! roughness length for tracers (heat and water), m
       		                          	 rough_scale         => NULL()        ! roughness length for drag scaling
   real, pointer, dimension(:,:,:,:)   :: &  ! (lon, lat, tile, tracer)
        tr    => NULL()              ! tracers, including canopy air specific humidity, kg/kg

!   <DATA NAME="mask" TYPE="logical, pointer" DIM="3">
!     Land mask; true if land
!   </DATA>

   logical, pointer, dimension(:,:,:):: &
        mask =>NULL()        ! true if land

!   <DATA NAME="maskmap" TYPE="logical, pointer" DIM="2">
!     A pointer to an array indicating which logical processors are actually used for
!     the ocean code. The other logical processors would be all land points and
!     are not assigned to actual processors. This need not be assigned if all logical
!     processors are used. This variable is dummy and need not to be set, 
!     but it is needed to pass compilation.
!   </DATA>

   logical, pointer, dimension(:,:) :: maskmap =>NULL()  ! A pointer to an array indicating which
                                                         ! logical processors are actually used for
                                                         ! the ocean code. 

!   <DATA NAME="axes(2)" TYPE="integer" DIM="2">
!     Axes IDs for diagnostics
!   </DATA>

   integer :: axes(2)      ! axes IDs for diagnostics  
   logical :: pe

! --> esm insertion
   real, pointer, dimension(:,:,:)   :: &  ! (lon, lat, tile)
        t_sst =>null(),           &
        cice  =>null(),           &
        fice  =>null(),           &
        hice  =>null(),           &
        hsno  =>null()
! --> esm insertion

end type land_data_type


logical :: module_is_initialized =.FALSE.
character(len=128) :: version = '$Id: land_types.F90,v 17.0 2009/07/21 03:03:37 fms Exp $'
character(len=128) :: tagname = '$Name: mom4p1_pubrel_dec2009_nnz $'


contains ! -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


! ============================================================================

subroutine allocate_boundary_data (a2l, bnd, domain, n_tiles)
  type(atmos_land_boundary_type), intent(inout) :: a2l
  type(land_data_type), intent(inout) :: bnd     ! data to allocate
  type(domain2d),       intent(in)  :: domain  ! domain to allocate for
  integer,              intent(in)  :: n_tiles ! number of tiles

  ! ---- local vars ----------------------------------------------------------
  integer :: is,ie,js,je ! boundaries of the domain

  ! get the size of our computation domain
  call mpp_get_compute_domain ( domain, is,ie,js,je )

  ! allocate data according to the domain boundaries
  allocate ( &
       bnd % tile_size  (is:ie,js:je,n_tiles), & 
       bnd % discharge_runoff      (is:ie,js:je),   & 
       bnd % discharge_drainage    (is:ie,js:je),   &
       bnd % mask       (is:ie,js:je,n_tiles) )
  allocate ( &
       bnd % t_surf         (is:ie,js:je,n_tiles), &
       bnd % t_ca           (is:ie,js:je,n_tiles), &
       bnd % tr             (is:ie,js:je,n_tiles,1), &     ! one tracer for q?
       bnd % albedo         (is:ie,js:je,n_tiles), &
       bnd % albedo_vis_dir (is:ie,js:je,n_tiles), &
       bnd % albedo_nir_dir (is:ie,js:je,n_tiles), &
       bnd % albedo_vis_dif (is:ie,js:je,n_tiles), &
       bnd % albedo_nir_dif (is:ie,js:je,n_tiles), &
       bnd % rough_mom      (is:ie,js:je,n_tiles), &
       bnd % rough_heat     (is:ie,js:je,n_tiles), &
       bnd % rough_scale    (is:ie,js:je,n_tiles), &
       bnd % mask       (is:ie,js:je,n_tiles) )

!--> esm insertion
  allocate(  bnd % t_sst         (is:ie,js:je,n_tiles))
  allocate(  bnd % cice (is:ie,js:je,n_tiles))
  allocate(  bnd % fice (is:ie,js:je,n_tiles))
  allocate(  bnd % hice (is:ie,js:je,n_tiles))
  allocate(  bnd % hsno (is:ie,js:je,n_tiles))
!<-- esm insertion

  bnd%t_surf = 273.0
  bnd%t_ca = 273.0
  bnd%tr = 0.0
  bnd%albedo = 0.0
  bnd % albedo_vis_dir = 0.0
  bnd % albedo_nir_dir = 0.0
  bnd % albedo_vis_dif = 0.0
  bnd % albedo_nir_dif = 0.0
  bnd%rough_mom = 0.01
  bnd%rough_heat = 0.01
  bnd%rough_scale = 1.0
  bnd % discharge_drainage = 0.0
  bnd % discharge_runoff = 0.0

!--> esm insertion
  bnd%t_sst = 273.0
  bnd%cice  = 0.0
  bnd%fice  = 0.0
  bnd%hice  = 0.0
  bnd%hsno  = 0.0
!<-- esm insertion

  allocate( a2l % runoff  (is:ie,js:je,n_tiles) )
  allocate( a2l % drainage(is:ie,js:je,n_tiles) )
  allocate( a2l % t_flux  (is:ie,js:je,n_tiles) )
  allocate( a2l % q_flux  (is:ie,js:je,n_tiles) )
  allocate( a2l % tr_flux  (is:ie,js:je,n_tiles,1) )     ! one tracer for q?
  allocate( a2l % dfdtr    (is:ie,js:je,n_tiles,1) )     ! one tracer for q?
  allocate( a2l % lw_flux (is:ie,js:je,n_tiles) )
  allocate( a2l % sw_flux (is:ie,js:je,n_tiles) )
  allocate( a2l % lprec   (is:ie,js:je,n_tiles) )
  allocate( a2l % fprec   (is:ie,js:je,n_tiles) )
  allocate( a2l % tprec   (is:ie,js:je,n_tiles) )
  allocate( a2l % dhdt    (is:ie,js:je,n_tiles) )
  allocate( a2l % dedt    (is:ie,js:je,n_tiles) )
  allocate( a2l % dedq    (is:ie,js:je,n_tiles) )
  allocate( a2l % drdt    (is:ie,js:je,n_tiles) )
  allocate( a2l % drag_q  (is:ie,js:je,n_tiles) )
  allocate( a2l % p_surf  (is:ie,js:je,n_tiles) )
  allocate( a2l % sw_flux_down_vis_dir   (is:ie,js:je,n_tiles) )
  allocate( a2l % sw_flux_down_total_dir (is:ie,js:je,n_tiles) )
  allocate( a2l % sw_flux_down_vis_dif   (is:ie,js:je,n_tiles) )
  allocate( a2l % sw_flux_down_total_dif (is:ie,js:je,n_tiles) )


! set up initial values (discharge_heat and discharge_snow_heat are set to zero and never change)
  a2l % runoff = 0.0
  a2l % drainage = 0.0

end subroutine allocate_boundary_data


subroutine deallocate_boundary_data ( a2l, bnd )
  type(atmos_land_boundary_type), intent(inout) :: a2l
  type(land_data_type), intent(inout) :: bnd  ! data to deallocate

  deallocate ( &
       bnd % tile_size  , & 
       bnd % discharge_runoff,      & 
       bnd % discharge_drainage,      &
       bnd % mask,       &
       bnd%t_surf, &
       bnd%t_ca, &
       bnd%tr, &
       bnd%albedo, &
       bnd % albedo_vis_dir, & 
       bnd % albedo_nir_dir, & 
       bnd % albedo_vis_dif, & 
       bnd % albedo_nir_dif, & 
       bnd%rough_mom , &
       bnd%rough_heat , &
       bnd%rough_scale )

!--> esm insertion
  deallocate(  bnd % t_sst)
  deallocate(  bnd % cice )
  deallocate(  bnd % fice )
  deallocate(  bnd % hice )
  deallocate(  bnd % hsno )
!<-- esm insertion

  deallocate( a2l % runoff )
  deallocate( a2l % drainage )
  deallocate( a2l % t_flux  )
  deallocate( a2l % q_flux  )
  deallocate( a2l % tr_flux )     ! one tracer for q?
  deallocate( a2l % dfdtr   )     ! one tracer for q?
  deallocate( a2l % lw_flux )
  deallocate( a2l % sw_flux )
  deallocate( a2l % lprec   )
  deallocate( a2l % fprec   )
  deallocate( a2l % tprec   )
  deallocate( a2l % dhdt    )
  deallocate( a2l % dedt    )
  deallocate( a2l % dedq    )
  deallocate( a2l % drdt    )
  deallocate( a2l % drag_q  )
  deallocate( a2l % p_surf  )
  deallocate( a2l % sw_flux_down_vis_dir   )
  deallocate( a2l % sw_flux_down_total_dir )
  deallocate( a2l % sw_flux_down_vis_dif   )
  deallocate( a2l % sw_flux_down_total_dif )

end subroutine deallocate_boundary_data

end module land_types_mod
