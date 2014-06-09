#!/usr/bin/env bash

if [ -d "script" ]; then
  cd script;
fi

# overwrite_modifications=1 = não escreva nada antes do lugar indicado nos arquivos do schema!!

perl sppm_web_create.pl model DB DBIC::Schema SPPM::Schema create=static components=TimeStamp,PassphraseColumn 'dbi:Pg:dbname=sppm_dev;host=localhost' postgres system quote_names=1 overwrite_modifications=1