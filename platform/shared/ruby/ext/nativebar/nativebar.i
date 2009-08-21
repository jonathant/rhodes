/* nativebar.i */
%module NativeBar
%{
	extern void create_nativebar(int bar_type, int nparams, char** params);
	#define create create_nativebar
%}

%typemap(in) (int nparams, char** params) {
	VALUE input_arr = $input;
	int arr_len = 0;
	int len = RARRAY_LEN(input_arr);
	char **ret_val = (char **)malloc(3*len*sizeof(char*));
	for(int i=0; i<len; i++) {
		char *val1, *val2, *val3;
		VALUE hash = rb_ary_entry($input,i);
		VALUE keys_arr = rb_funcall(hash, rb_intern("keys"), 0, NULL);
		int keys_len = RARRAY_LEN(keys_arr);
		val1 = val2 = val3 = NULL;
		for(int j=0; j<keys_len; j++) {
			VALUE val;
			char *tmp;
			VALUE key = rb_ary_entry(keys_arr, j);
			VALUE data = rb_hash_aref(hash,key);
			char *key_str = StringValuePtr(key);
			switch(TYPE(data)) {
				case T_STRING:
					tmp = StringValuePtr(data);
					break;
				case T_SYMBOL:
					val = rb_funcall(data, rb_intern("to_s"), 0, NULL);
					tmp = StringValuePtr(val);
					break;
				default:
					tmp = NULL;
					break;
			
			}
			if (!strcmp(key_str,"label")) {
				val1 = tmp;
			} else if (!strcmp(key_str, "action")) {
				val2 = tmp;
			} else if (!strcmp(key_str, "icon")) {
				val3 = tmp;
			} 
		}
		ret_val[arr_len++] = val1;
		ret_val[arr_len++] = val2;
		ret_val[arr_len++] = val3;
	}
	$1 = arr_len;
	$2 = ret_val;
}

%typemap(freearg) (int nparams, char** params) {
 free((void *) $2);
}

extern void create(int bar_type, int nparams, char** params);