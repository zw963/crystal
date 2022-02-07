int funptr(int (*fun_ptr)(int)) {
  return (*fun_ptr)(12);
}

int (*fun_ptr)(int);

void funptr_set(int (*f)(int)) {
  fun_ptr = f;
}

int funptr_call() {
  (*fun_ptr)(42);
}
