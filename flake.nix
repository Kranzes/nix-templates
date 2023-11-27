{
  outputs = _: {
    templates = {
      rust = {
        path = ./rust;
        description = "Rust template";
      };
      go = {
        path = ./go;
        description = "Go template";
      };
    };
  };
}
