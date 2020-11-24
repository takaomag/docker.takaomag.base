#!/bin/bash

for pf in ~/.profile.d/*; do
  [[ ! -r "${pf}" ]] || . "${pf}"
done
