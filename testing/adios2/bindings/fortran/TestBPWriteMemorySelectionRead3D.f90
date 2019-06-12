program TestBPWriteMemorySelectionRead3D
  use mpi
  use adios2

  implicit none

  type(adios2_adios) :: adios
  type(adios2_io) :: ioPut, ioGet
  type(adios2_engine) :: bpWriter, bpReader
  type(adios2_variable), dimension(6) :: vars, vars_in

  integer(kind=1), dimension(:, :, :), allocatable :: data_i1, in_data_i1
  integer(kind=2), dimension(:, :, :), allocatable :: data_i2, in_data_i2
  integer(kind=4), dimension(:, :, :), allocatable :: data_i4, in_data_i4
  integer(kind=8), dimension(:, :, :), allocatable :: data_i8, in_data_i8
  real(kind=4), dimension(:, :, :), allocatable :: data_r4, in_data_r4
  real(kind=8), dimension(:, :, :), allocatable :: data_r8, in_data_r8

  integer(kind=1) :: min_i1, max_i1
  integer(kind=2) :: min_i2, max_i2
  integer(kind=4) :: min_i4, max_i4
  integer(kind=8) :: min_i8, max_i8
  real(kind=4)    :: min_r4, max_r4
  real(kind=8)    :: min_r8, max_r8

  integer(kind=8), dimension(3) :: ishape, istart, icount
  integer(kind=8), dimension(3) :: memory_start, memory_count
  integer :: ierr, irank, isize, nx, ny, nz, nsteps, s, step_status
  integer(kind=8) :: ghost_x, ghost_y, ghost_z, i, j, k, current_step

  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, irank, ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, isize, ierr)

  nsteps = 3

  nx = 10 ! fastest
  ny = 20
  nz = 2

  ghost_x = 2
  ghost_y = 4
  ghost_z = 1

  allocate (data_i1(nx + 2* ghost_x, ny + 2* ghost_y, nz + 2*ghost_z))
  allocate (data_i2(nx + 2* ghost_x, ny + 2* ghost_y, nz + 2*ghost_z))
  allocate (data_i4(nx + 2* ghost_x, ny + 2* ghost_y, nz + 2*ghost_z))
  allocate (data_i8(nx + 2* ghost_x, ny + 2* ghost_y, nz + 2*ghost_z))
  allocate (data_r4(nx + 2* ghost_x, ny + 2* ghost_y, nz + 2*ghost_z))
  allocate (data_r8(nx + 2* ghost_x, ny + 2* ghost_y, nz + 2*ghost_z))

  data_i1 = -1
  data_i2 = -1
  data_i4 = -1
  data_i8 = -1_8
  data_r4 = -1.0
  data_r8 = -1.0_8

  call adios2_init(adios, MPI_COMM_WORLD, adios2_debug_mode_on, ierr)

  ! Writer
  call adios2_declare_io(ioPut, adios, 'MemSelWriter', ierr)

  ishape = (/nx, ny, isize*nz/)
  istart = (/0,   0, irank*nz/)
  icount = (/nx, ny,       nz/)

  memory_start = (/ ghost_x, ghost_y, ghost_z /)
  memory_count = (/ nx + 2* ghost_x, ny + 2* ghost_y, nz + 2* ghost_z /)

  call adios2_define_variable(vars(1), ioPut, 'var_i1', adios2_type_integer1, &
                              3, ishape, istart, icount, &
                              adios2_constant_dims, ierr)

  call adios2_define_variable(vars(2), ioPut, 'var_i2', adios2_type_integer2, &
                              3, ishape, istart, icount, &
                              adios2_constant_dims, ierr)

  call adios2_define_variable(vars(3), ioPut, 'var_i4', adios2_type_integer4, &
                              3, ishape, istart, icount, &
                              adios2_constant_dims, ierr)

  call adios2_define_variable(vars(4), ioPut, 'var_i8', adios2_type_integer8, &
                              3, ishape, istart, icount, &
                              adios2_constant_dims, ierr)

  call adios2_define_variable(vars(5), ioPut, 'var_r4', adios2_type_real, &
                              3, ishape, istart, icount, &
                              adios2_constant_dims, ierr)

  call adios2_define_variable(vars(6), ioPut, 'var_r8', adios2_type_dp, &
                              3, ishape, istart, icount, &
                              adios2_constant_dims, ierr)

  call adios2_set_memory_selection(vars(1), 3, memory_start, memory_count, ierr)
  call adios2_set_memory_selection(vars(2), 3, memory_start, memory_count, ierr)
  call adios2_set_memory_selection(vars(3), 3, memory_start, memory_count, ierr)
  call adios2_set_memory_selection(vars(4), 3, memory_start, memory_count, ierr)
  call adios2_set_memory_selection(vars(5), 3, memory_start, memory_count, ierr)
  call adios2_set_memory_selection(vars(6), 3, memory_start, memory_count, ierr)

  call adios2_open(bpWriter, ioPut, 'MemSel3D_f.bp', adios2_mode_write, ierr)

  do s=0,nsteps-1
    data_i1(ghost_x+1:nx+ghost_x+1,ghost_y+1:ny+ghost_y+1,ghost_z+1:nz+ghost_z+1) = s
    data_i2(ghost_x+1:nx+ghost_x+1,ghost_y+1:ny+ghost_y+1,ghost_z+1:nz+ghost_z+1) = s
    data_i4(ghost_x+1:nx+ghost_x+1,ghost_y+1:ny+ghost_y+1,ghost_z+1:nz+ghost_z+1) = s
    data_i8(ghost_x+1:nx+ghost_x+1,ghost_y+1:ny+ghost_y+1,ghost_z+1:nz+ghost_z+1) = s
    data_r4(ghost_x+1:nx+ghost_x+1,ghost_y+1:ny+ghost_y+1,ghost_z+1:nz+ghost_z+1) = s
    data_r8(ghost_x+1:nx+ghost_x+1,ghost_y+1:ny+ghost_y+1,ghost_z+1:nz+ghost_z+1) = s

    call adios2_begin_step(bpWriter, ierr)
    call adios2_put(bpWriter, vars(1), data_i1, ierr)
    call adios2_put(bpWriter, vars(2), data_i2, ierr)
    call adios2_put(bpWriter, vars(3), data_i4, ierr)
    call adios2_put(bpWriter, vars(4), data_i8, ierr)
    call adios2_put(bpWriter, vars(5), data_r4, ierr)
    call adios2_put(bpWriter, vars(6), data_r8, ierr)
    call adios2_end_step(bpWriter, ierr)

  end do

  call adios2_close(bpWriter, ierr)

  deallocate (data_i1)
  deallocate (data_i2)
  deallocate (data_i4)
  deallocate (data_i8)
  deallocate (data_r4)
  deallocate (data_r8)

  call MPI_Barrier(MPI_COMM_WORLD, ierr)

  ! reader goes here
  call adios2_declare_io(ioGet, adios, 'MemSelReader', ierr)

  call adios2_open(bpReader, ioGet, 'MemSel3D_f.bp', adios2_mode_read, ierr)

  allocate (in_data_i1(nx, ny, isize*nz))
  allocate (in_data_i2(nx, ny, isize*nz))
  allocate (in_data_i4(nx, ny, isize*nz))
  allocate (in_data_i8(nx, ny, isize*nz))
  allocate (in_data_r4(nx, ny, isize*nz))
  allocate (in_data_r8(nx, ny, isize*nz))

  do
    call adios2_begin_step(bpReader, adios2_step_mode_read, -1., &
                           step_status, ierr)

    if(step_status == adios2_step_status_end_of_stream) exit

    call adios2_inquire_variable(vars_in(1), ioGet, 'var_i1', ierr)
    if( vars_in(1)%valid .eqv. .false. ) stop 'i1 invalid error'
    if( vars_in(1)%name /= 'var_i1' ) stop 'i1 name error'
    if( vars_in(1)%type /= adios2_type_integer1 ) stop 'i1 type error'
    if( vars_in(1)%ndims /= 3 ) stop 'i1 dims error'
    call adios2_variable_min(min_i1, vars_in(1), ierr)
    if(min_i1 /= 0 ) stop 'i1 min error'
    call adios2_variable_max(max_i1, vars_in(1), ierr)
    if(max_i1 /= nsteps-1 ) stop 'i1 max error'

    call adios2_inquire_variable(vars_in(2), ioGet, 'var_i2', ierr)
    if( vars_in(2)%valid .eqv. .false. ) stop 'i2 invalid error'
    if( vars_in(2)%name /= 'var_i2' ) stop 'i2 name error'
    if( vars_in(2)%type /= adios2_type_integer2 ) stop 'i2 type error'
    if( vars_in(2)%ndims /= 3 ) stop 'i2 dims error'
    call adios2_variable_min(min_i2, vars_in(2), ierr)
    if(min_i2 /= 0 ) stop 'i2 min error'
    call adios2_variable_max(max_i2, vars_in(2), ierr)
    if(max_i2 /= nsteps-1 ) stop 'i2 max error'

    call adios2_inquire_variable(vars_in(3), ioGet, 'var_i4', ierr)
    if( vars_in(3)%valid .eqv. .false. ) stop 'i4 invalid error'
    if( vars_in(3)%name /= 'var_i4' ) stop 'i4 name error'
    if( vars_in(3)%type /= adios2_type_integer4 ) stop 'i4 type error'
    if( vars_in(3)%ndims /= 3 ) stop 'i4 dims error'
    call adios2_variable_min(min_i4, vars_in(3), ierr)
    if(min_i4 /= 0 ) stop 'i4 min error'
    call adios2_variable_max(max_i4, vars_in(3), ierr)
    if(max_i4 /= nsteps-1 ) stop 'i4 max error'

    call adios2_inquire_variable(vars_in(4), ioGet, 'var_i8', ierr)
    if( vars_in(4)%valid .eqv. .false. ) stop 'i8 invalid error'
    if( vars_in(4)%name /= 'var_i8' ) stop 'i8 name error'
    if( vars_in(4)%type /= adios2_type_integer8 ) stop 'i8 type error'
    if( vars_in(4)%ndims /= 3 ) stop 'i8 dims error'
    call adios2_variable_min(min_i8, vars_in(4), ierr)
    if(min_i8 /= 0 ) stop 'i8 min error'
    call adios2_variable_max(max_i8, vars_in(4), ierr)
    if(max_i8 /= nsteps-1 ) stop 'i8 max error'

    call adios2_inquire_variable(vars_in(5), ioGet, 'var_r4', ierr)
    if( vars_in(5)%valid .eqv. .false. ) stop 'r4 invalid error'
    if( vars_in(5)%name /= 'var_r4' ) stop 'r4 name error'
    if( vars_in(5)%type /= adios2_type_real ) stop 'r4 type error'
    if( vars_in(5)%ndims /= 3 ) stop 'r4 dims error'
    call adios2_variable_min(min_r4, vars_in(5), ierr)
    if(min_r4 /= 0 ) stop 'r4 min error'
    call adios2_variable_max(max_r4, vars_in(5), ierr)
    if(max_r4 /= nsteps-1 ) stop 'r4 max error'

    call adios2_inquire_variable(vars_in(6), ioGet, 'var_r8', ierr)
    if( vars_in(6)%valid .eqv. .false. ) stop 'r8 invalid error'
    if( vars_in(6)%name /= 'var_r8' ) stop 'r8 name error'
    if( vars_in(6)%type /= adios2_type_dp ) stop 'r8 type error'
    if( vars_in(6)%ndims /= 3 ) stop 'r8 dims error'
    call adios2_variable_min(min_r8, vars_in(6), ierr)
    if(min_r8 /= 0 ) stop 'r8 min error'
    call adios2_variable_max(max_r8, vars_in(6), ierr)
    if(max_r8 /= nsteps-1 ) stop 'r8 max error'

    call adios2_get(bpReader, 'var_i1', in_data_i1, ierr)
    call adios2_get(bpReader, 'var_i2', in_data_i2, ierr)
    call adios2_get(bpReader, 'var_i4', in_data_i4, ierr)
    call adios2_get(bpReader, 'var_i8', in_data_i8, ierr)
    call adios2_get(bpReader, 'var_r4', in_data_r4, ierr)
    call adios2_get(bpReader, 'var_r8', in_data_r8, ierr)
    call adios2_end_step(bpReader, ierr)

    call adios2_current_step(current_step, bpReader, ierr)

    do k=1,isize*nz
      do j=1,ny
        do i=1,nx
          if(in_data_i1(i,j,k) /= current_step) stop 'i1 read error'
          if(in_data_i2(i,j,k) /= current_step) stop 'i2 read error'
          if(in_data_i4(i,j,k) /= current_step) stop 'i4 read error'
          if(in_data_i8(i,j,k) /= current_step) stop 'i8 read error'
          if(in_data_r4(i,j,k) /= current_step) stop 'r4 read error'
          if(in_data_r8(i,j,k) /= current_step) stop 'r8 read error'
        end do
      end do
    end do

  end do

  call adios2_close(bpReader, ierr)

  deallocate (in_data_i1)
  deallocate (in_data_i2)
  deallocate (in_data_i4)
  deallocate (in_data_i8)
  deallocate (in_data_r4)
  deallocate (in_data_r8)

  call adios2_finalize(adios, ierr)
  call MPI_Finalize(ierr)

end program TestBPWriteMemorySelectionRead3D
