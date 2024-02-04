# frozen_string_literal: true


GREEN = "\e[32m"
LIGHT_YELLOW = "\e[93m"
MAGENTA = "\e[35m"
RED = "\e[31m"
RESET = "\e[0m"
YELLOW = "\e[33m"


def quit?
  begin
    # See if a 'Q' has been typed yet
    while (c = STDIN.read_nonblock(1))
      return true if c.upcase == 'Q'
    end
  rescue Errno::EINTR, Errno::EAGAIN
    # No 'Q' found
    false
  rescue EOFError
    # quit on the end of the input stream
    # (user hit CTRL-D)
    true
  end
end