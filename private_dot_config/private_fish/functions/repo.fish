function repo
  ghq list --full-path | peco | read dist
  cd $dist
end
