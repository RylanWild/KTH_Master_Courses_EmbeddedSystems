PACKAGE const_package IS
	
	CONSTANT instruction_no         : integer := 27;
	CONSTANT mem_no        : integer := 4;
	CONSTANT mem_load_cycles        : integer := 4;
	CONSTANT reg_load_cycles        : integer := 4;
	CONSTANT execution_start_cycle  : integer := 37;
	CONSTANT total_execution_cycle  : integer := 72;
	CONSTANT period                 : time    := 12 NS;
	CONSTANT half_period            : time    := 6 NS;
	
END ;

