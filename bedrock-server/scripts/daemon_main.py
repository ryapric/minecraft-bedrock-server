#!/usr/bin/env python3

import daemon_utils as u

def main():
    if u.doorknocker_was_hit():
        u.start_worker_instance()
    else:
        if u.worker_is_on():
            u.stop_worker_instance()
    u.backup_gamedata_to_s3()
# end main

if __name__ == '__main__':
    main()
