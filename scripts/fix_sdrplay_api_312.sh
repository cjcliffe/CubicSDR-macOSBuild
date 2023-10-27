#!/bin/bash

# SDRPlay 3.12 installs includes to non-standard include path; move them to the standard one
sudo mv /usr/local/inc/sdrplay_api* /usr/local/include/ || true
# SDRPlay 3.12 API internal binary references non-existant lib file; add a symlink for the missing file
sudo ln -s /Library/SDRplayAPI/3.12.0/lib/libsdrplay_api.so.3.12.0 /usr/local/lib/libsdrplay_api_x86_64.so.3.12
# SDRPlay 3.12 service references /usr/local/bin but it was not linked
sudo ln -s /Library/SDRplayAPI/3.12.0/bin/sdrplay_apiService /usr/local/bin/sdrplay_apiService
