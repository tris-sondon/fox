module m_common_buffer

  use m_common_error, only : FoX_warning

  implicit none
  private
  
  ! At this point we use a fixed-size buffer. 
  ! Note however that buffer overflows will only be
  ! triggered by overly long *unbroken* pcdata values, or
  ! by overly long attribute values. Hopefully
  ! element or attribute names are "short enough".
  !
  ! In a forthcoming implementation it could be made dynamical...
  
  ! MAX_BUFF_SIZE cannot be bigger than the maximum available
  ! record length for a compiler. In practice, this means
  ! 1024 seems to be the biggest available size.
  
  integer, parameter :: MAX_BUFF_SIZE  = 1024
  integer, parameter :: BUFF_SIZE_WARNING  = 0.9 * MAX_BUFF_SIZE
  
  type buffer_t
    private
    integer                       :: size
    character(len=MAX_BUFF_SIZE)  :: str
    integer                       :: unit
  end type buffer_t
  
  public :: buffer_t
  
  public :: add_to_buffer
  public :: print_buffer, str, char, len
  public :: buffer_to_chararray
  public :: buffer_nearly_full
  public :: reset_buffer
  public :: dump_buffer

  interface str
    module procedure buffer_to_str
  end interface
  
  interface char
    module procedure buffer_to_str
  end interface
  
  interface len
    module procedure buffer_length
  end interface
  
contains

  subroutine add_to_buffer(s,buffer)
    character(len=*), intent(in)   :: s
    type(buffer_t), intent(inout)  :: buffer
    
    integer   :: i, n, len_b, len_s

    !If we overreach our buffer size, we will be unable to
    !output any more characters without a newline.

    if (buffer%size + len(s) > MAX_BUFF_SIZE) then
      call FoX_warning("Buffer overflow impending; inserting newlines, sorry")
      call dump_buffer(buffer)
    endif
    
    n = 1
    do i = 1, len(s)/MAX_BUFF_SIZE
      write(buffer%unit, '(a)') s(n:n+MAX_BUFF_SIZE-1)
      n = n + MAX_BUFF_SIZE
    enddo

    len_s = len(s(n:)) 
    len_b = buffer%size
    buffer%str(len_b+1:len_b+len_s) = s(n:)
    buffer%size = buffer%size + len_s

  end subroutine add_to_buffer


  subroutine reset_buffer(buffer, unit)
    type(buffer_t), intent(inout)  :: buffer
    integer, intent(in), optional :: unit

    buffer%size = 0
    if (present(unit)) then
      buffer%unit = unit
    else 
      buffer%unit = 6
    endif
    
  end subroutine reset_buffer
  

  subroutine print_buffer(buffer)
    type(buffer_t), intent(in)  :: buffer
    
    integer :: i
    
    write(unit=6,fmt="(a)") buffer%str(:buffer%size)

  end subroutine print_buffer


  function buffer_to_str(buffer) result(str)
    type(buffer_t), intent(in)          :: buffer
    character(len=buffer%size)          :: str
    
    str = buffer%str(:buffer%size)
  end function buffer_to_str


  function buffer_to_chararray(buffer) result(str)
    type(buffer_t), intent(in)               :: buffer
    character(len=1), dimension(buffer%size) :: str
    integer :: i
    
    do i = 1, buffer%size
      str(i) = buffer%str(i:i)
    enddo
  end function buffer_to_chararray


  function buffer_nearly_full(buffer) result(warn)
    type(buffer_t), intent(in)          :: buffer
    logical                             :: warn
    
    warn = buffer%size > BUFF_SIZE_WARNING
    
  end function buffer_nearly_full


  function buffer_length(buffer) result(length)
    type(buffer_t), intent(in)          :: buffer
    integer                             :: length
    
    length = buffer%size 

  end function buffer_length

  
  subroutine dump_buffer(buffer, lf)
    type(buffer_t), intent(inout) :: buffer
    logical, intent(in), optional :: lf

    logical :: lf_

    if (present(lf)) then
      lf_ = lf
    else
      lf_ = .true.
    endif

    if (lf_) then
      write(buffer%unit, '(a)') buffer%str(:buffer%size)
    else
      write(buffer%unit, '(a)', advance='no') buffer%str(:buffer%size)
    endif
    buffer%size = 0
  end subroutine dump_buffer

end module m_common_buffer
