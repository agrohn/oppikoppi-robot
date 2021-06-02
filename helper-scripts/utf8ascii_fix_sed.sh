#!/bin/bash

#  This file is part of oppikoppi.
#  Copyright (C) 2021 Anssi Gröhn

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.

if [ -f $1 ]; then
    sed -i -e "s/\\\u00c0/À/g" -e "s/\\\u00c1/Á/g" -e "s/\\\u00c2/Â/g" -e "s/\\\u00c3/Ã/g" -e "s/\\\u00c4/Ä/g" -e "s/\\\u00c5/Å/g" -e "s/\\\u00c6/Æ/g" -e "s/\\\u00c7/Ç/g" -e "s/\\\u00c8/È/g" -e "s/\\\u00c9/É/g" -e "s/\\\u00ca/Ê/g" -e "s/\\\u00cb/Ë/g" -e "s/\\\u00cc/Ì/g" -e "s/\\\u00cd/Í/g" -e "s/\\\u00ce/Î/g" -e "s/\\\u00cf/Ï/g" -e "s/\\\u00d0/Ð/g" -e "s/\\\u00d1/Ñ/g" -e "s/\\\u00d2/Ò/g" -e "s/\\\u00d3/Ó/g" -e "s/\\\u00d4/Ô/g" -e "s/\\\u00d5/Õ/g" -e "s/\\\u00d6/Ö/g" -e "s/\\\u00d7/×/g" -e "s/\\\u00d8/Ø/g" -e "s/\\\u00d9/Ù/g" -e "s/\\\u00da/Ú/g" -e "s/\\\u00db/Û/g" -e "s/\\\u00dc/Ü/g" -e "s/\\\u00dd/Ý/g" -e "s/\\\u00de/Þ/g" -e "s/\\\u00df/ß/g" -e "s/\\\u00e0/à/g" -e "s/\\\u00e1/á/g" -e "s/\\\u00e2/â/g" -e "s/\\\u00e3/ã/g" -e "s/\\\u00e4/ä/g" -e "s/\\\u00e5/å/g" -e "s/\\\u00e6/æ/g" -e "s/\\\u00e7/ç/g" -e "s/\\\u00e8/è/g" -e "s/\\\u00e9/é/g" -e "s/\\\u00ea/ê/g" -e "s/\\\u00eb/ë/g" -e "s/\\\u00ec/ì/g" -e "s/\\\u00ed/í/g" -e "s/\\\u00ee/î/g" -e "s/\\\u00ef/ï/g" -e "s/\\\u00f0/ð/g" -e "s/\\\u00f1/ñ/g" -e "s/\\\u00f2/ò/g" -e "s/\\\u00f3/ó/g" -e "s/\\\u00f4/ô/g" -e "s/\\\u00f5/õ/g" -e "s/\\\u00f6/ö/g" -e "s/\\\u00f7/÷/g" -e "s/\\\u00f8/ø/g" -e "s/\\\u00f9/ù/g" -e "s/\\\u00fa/ú/g" -e "s/\\\u00fb/û/g" -e "s/\\\u00fc/ü/g" -e "s/\\\u00fd/ý/g" -e "s/\\\u00fe/þ/g" -e "s/\\\u00ff/ÿ/g" $1
fi
