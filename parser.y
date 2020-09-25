%{
	struct Token
	{
		char string_val[1024];
		char val_type[10];
		int index;
		int int_val;
		float float_val;
		int reg;
		int label;
	};
	typedef struct Token Token;
	#define YYSTYPE Token
	
	struct int_stack
	{
		int arr[1024];
		int top;
	}if_stack,scope_stack;
	
	struct string_stack
	{
		char arr[1024][10];
		int top;
	};
	
	struct sym
	{
		char id[1024];
		char func[1024];
		struct int_stack scope_stack;
		struct string_stack type_stack;
		struct int_stack constant_stack;
		struct int_stack initialized_stack;
		struct int_stack used_stack;
	}sym_table[1024];
	
	struct func
	{
		char id[1024];
		char return_type[10];
		int first_param_reg;
		int num_of_params;
		int returned_reg;
		char *param_list[1024];
		char *param_types_list[1024];
	}func_table[1024];
	
	void int_stack_init(struct int_stack *s);
	void int_stack_push(struct int_stack *s, int val);
	int int_stack_pop(struct int_stack *s);
	int int_stack_top(struct int_stack *s);
	int int_stack_empty(struct int_stack *s);
	void string_stack_init(struct string_stack *s);
	void string_stack_push(struct string_stack *s, char *val);
	char* string_stack_pop(struct string_stack *s);
	char* string_stack_top(struct string_stack *s);
	int string_stack_empty(struct string_stack *s);
	void init_string_list(char **param_list);
	void add_string_to_list(char **param_list, char* addedParam);
	void init_sym_table();
	void init_func_table();
	int get_sym_index(char *id);
	int get_func_index(char *id);
	char* get_error_msg(char* part1, char* param, char* part2);

    #include <stdio.h>
	#include <string.h>
    int yylex(void);
    void yyerror(char *);
	extern FILE * yyin;
	extern FILE * yyout;
	int regCount=1,labelCount=1,if_labelCount=1;
	char current_func[1024];
	char calling_func[1024];
	int current_index;
	int scopeCount;
	int passedParamCount;
	int yylineno;
	int returned;
	
	int regcomp=0;
	int labeljmp=0;
	int labelout=0;
	int whileiterator=0;
	int whileiteratorout=0;
	int foriterator=0;
	int foriteratorout=0;
	int foroutt=0;
	int incc=0;
	int forstat=0;
	int forincrement=0;
	int incrementiterator=0;
	int breaklabel=0;
	int caselabel=0;
	int casecomp=0;
	int caseiterator=0;
	int doiterator=0;
	int dolabel=0;
	int whilebreakiterator=0;
	int dowhilebreakiterator=0;
	int forbreakiterator=0;
	int switchiterator=0;
	int breakiterator;
	int casebreaklabel=0;
	
	int whilelabels [255] ;
	int  whilelabelsout [255];
	int forlabels [255] ;
	int forincrements[255];
	int forstats [255];
	int  forlabelsout [255];
	int  caselabels [255];
	int  dowhilelabels [255];
	int whilebreaks [255];
	int forbreaks [255];
	int dowhilebreaks [255];
	int breaklabels[255];
	int casebreaklabels [255];
%}

%token TYPE VOID constant ID int_value float_value bool_value EE NE GE LE IF ELSEIF ELSE WHILE DO FOR SWITCH CASE DEFAULT BREAK RETURN

%%

program:
		program function
		|
		;
		
statement:
			simple_statement ';'
			|complex_statement
			;

simple_statement:
					declaration
					|assignment
					|function_call	{
										current_index=get_func_index($1.string_val);
										if(strcmp(func_table[current_index].return_type,"void")!=0)
												yyerror("warning: returned value of function not used");
									}
					|return_from_func
					|BREAK	{
								if (whilebreaks[0]==0 && dowhilebreaks[0]==0 &&forbreaks[0]==0 )
									{
										yyerror("semantic error: break outside loop");
									}
									else
									{
										fprintf(yyout,"jmp breaklabel%d\n",breaklabel);
										breaklabels[breakiterator]=breaklabel;
										breaklabel++;
										breakiterator++;
										
									}
							}
					;
					
complex_statement:
					if_then_else
					|while_loop
					|do_while_loop
					|for_loop
					|switch_case
					|block
					;
			
block:
		block_start statements block_end	{
												for(int i=0;i<1024;i++)
												{
													if(int_stack_empty(&sym_table[i].scope_stack)==0&&strcmp(sym_table[i].func,current_func)==0)
													{
														if(int_stack_top(&sym_table[i].scope_stack)==int_stack_top(&scope_stack))
														{
															if(int_stack_top(&sym_table[i].used_stack)==0)
																yyerror(get_error_msg("warning: identifier '",sym_table[i].id,"' is declared but never used"));
															fprintf(yyout,"pop %s\n",sym_table[i].id);
															int_stack_pop(&sym_table[i].scope_stack);
															string_stack_pop(&sym_table[i].type_stack);
															int_stack_pop(&sym_table[i].constant_stack);
															int_stack_pop(&sym_table[i].initialized_stack);
															int_stack_pop(&sym_table[i].used_stack);
														}
													}
												}
												int_stack_pop(&scope_stack);
											}
		;
		
block_start:
			'{'	{
					scopeCount=scopeCount+1;
					int_stack_push(&scope_stack,scopeCount);
				}
			;

block_end:
			'}'
			;
		
statements:
			statements statement
			|
			;
			
complex_statement_body:
						simple_statement ';'
						|block
						;

declaration:
			declaration_temp
			|constant constant_declaration_temp
			;
			
declaration_temp:
					TYPE ID	{
								current_index=get_sym_index($2.string_val);
								if(strcmp(sym_table[current_index].func,current_func)==0&&int_stack_empty(&sym_table[current_index].scope_stack)==0)
								{
									if(int_stack_top(&sym_table[current_index].scope_stack)==int_stack_top(&scope_stack))
										yyerror(get_error_msg("semantic error: identifier '",$2.string_val,"' is declared more than once in the same scope"));
								}
								else
								{
									strcpy(sym_table[current_index].id,$2.string_val);
									string_stack_push(&sym_table[current_index].type_stack,$1.string_val);
									strcpy(sym_table[current_index].func,current_func);
									int_stack_push(&sym_table[current_index].scope_stack,int_stack_top(&scope_stack));
									int_stack_push(&sym_table[current_index].initialized_stack,0);
									int_stack_push(&sym_table[current_index].constant_stack,0);
									int_stack_push(&sym_table[current_index].used_stack,0);
									fprintf(yyout,"push %s\n",$2.string_val);
								}
							}
					|TYPE ID '=' expression	{
												current_index=get_sym_index($2.string_val);
												if(strcmp(sym_table[current_index].func,current_func)==1&&int_stack_empty(&sym_table[current_index].scope_stack)==0)
												{
													if(int_stack_top(&sym_table[current_index].scope_stack)==int_stack_top(&scope_stack))
														yyerror(get_error_msg("semantic error: identifier '",$2.string_val,"' is declared more than once in the same scope"));
												}
												else
												{
													strcpy(sym_table[current_index].id,$2.string_val);
													string_stack_push(&sym_table[current_index].type_stack,$1.string_val);
													strcpy(sym_table[current_index].func,current_func);
													int_stack_push(&sym_table[current_index].scope_stack,int_stack_top(&scope_stack));
													int_stack_push(&sym_table[current_index].initialized_stack,1);
													int_stack_push(&sym_table[current_index].constant_stack,0);
													int_stack_push(&sym_table[current_index].used_stack,1);
													fprintf(yyout,"push %s\n",$2.string_val);
													fprintf(yyout,"mov %s,r%d\n",$2.string_val,$4.reg);
												}
												if(strcmp(string_stack_top(&sym_table[current_index].type_stack),"int")==0&&strcmp($4.val_type,"bool")==0)
													yyerror(get_error_msg("semantic error: non-int value assigned to the int variable '",$2.string_val,"'"));
												else if(strcmp(string_stack_top(&sym_table[current_index].type_stack),"bool")==0&&strcmp($4.val_type,"int")==0)
													yyerror(get_error_msg("semantic error: non-bool value assigned to the bool variable '",$2.string_val,"'"));
											}
					|error ID	{yyerror("syntax error: expected type name");}
					|TYPE error '=' expression	{yyerror("syntax error: illegal identifier");}
					|TYPE ID error expression	{yyerror("syntax error: expected '='");}
					;

constant_declaration_temp:
							TYPE ID '=' expression	{
														current_index=get_sym_index($2.string_val);
														if(strcmp(sym_table[current_index].func,current_func)==0&&int_stack_empty(&sym_table[current_index].scope_stack)==0)
														{
															if(int_stack_top(&sym_table[current_index].scope_stack)==int_stack_top(&scope_stack))
																yyerror(get_error_msg("semantic error: identifier '",$2.string_val,"' is declared more than once in the same scope"));
														}
														else
														{
															strcpy(sym_table[current_index].id,$2.string_val);
															string_stack_push(&sym_table[current_index].type_stack,$1.string_val);
															strcpy(sym_table[current_index].func,current_func);
															int_stack_push(&sym_table[current_index].scope_stack,int_stack_top(&scope_stack));
															int_stack_push(&sym_table[current_index].initialized_stack,1);
															int_stack_push(&sym_table[current_index].constant_stack,1);
															int_stack_push(&sym_table[current_index].used_stack,1);
															fprintf(yyout,"push %s\n",$2.string_val);
															fprintf(yyout,"mov %s,r%d\n",$2.string_val,$4.reg);
														}
														if(strcmp(string_stack_top(&sym_table[current_index].type_stack),"int")==0&&strcmp($4.val_type,"bool")==0)
															yyerror(get_error_msg("semantic error: non-int value assigned to the int variable '",$2.string_val,"'"));
														else if(strcmp(string_stack_top(&sym_table[current_index].type_stack),"bool")==0&&strcmp($4.val_type,"int")==0)
															yyerror(get_error_msg("semantic error: non-bool value assigned to the bool variable '",$2.string_val,"'"));
													}
							;
								
assignment:
						ID '=' expression	{
												current_index=get_sym_index($1.string_val);
												if(int_stack_empty(&sym_table[current_index].scope_stack)==1)
													yyerror(get_error_msg("semantic error: identifier '",$1.string_val,"' is undeclared"));
												else if(int_stack_top(&sym_table[current_index].constant_stack)==1)
													yyerror(get_error_msg("semantic error: identifier '",$1.string_val,"' is constant and being assigned a value"));
												else if(strcmp(string_stack_top(&sym_table[current_index].type_stack),"int")==0&&strcmp($3.val_type,"bool")==0)
													yyerror(get_error_msg("semantic error: non-int value assigned to the int variable '",$1.string_val,"'"));
												else if(strcmp(string_stack_top(&sym_table[current_index].type_stack),"bool")==0&&strcmp($3.val_type,"int")==0)
													yyerror(get_error_msg("semantic error: non-bool value assigned to the bool variable '",$1.string_val,"'"));
												int_stack_pop(&sym_table[current_index].initialized_stack);
												int_stack_push(&sym_table[current_index].initialized_stack,1);
												int_stack_pop(&sym_table[current_index].used_stack);
												int_stack_push(&sym_table[current_index].used_stack,1);
												fprintf(yyout,"mov %s,r%d\n",$1.string_val,$3.reg);
											}
						|error '=' expression	{yyerror("syntax error: illegal identifier");}
						|ID error expression	{yyerror("syntax error: expected '='");}
						;

expression:
			expression '|' term1	{
										if(strcmp($1.val_type,"bool")!=0||strcmp($3.val_type,"bool")!=0)
											yyerror("semantic error: OR operator used on non-int value");
										fprintf(yyout,"or r%d,r%d,r%d\n",regCount,$1.reg,$3.reg);
										strcpy($$.val_type,"bool");
										regcomp=regCount;
										casecomp=regCount;
										$$.reg=regCount;
										regCount=regCount+1;
									}
			|term1
			;
			
term1:
		term1 '&' term2	{
							if(strcmp($1.val_type,"bool")!=0||strcmp($3.val_type,"bool")!=0)
								yyerror("semantic error: AND operator used on non-bool value");
							fprintf(yyout,"and r%d,r%d,r%d\n",regCount,$1.reg,$3.reg);
							strcpy($$.val_type,"bool");
							regcomp=regCount;
							casecomp=regCount;
							$$.reg=regCount;
							regCount=regCount+1;
						}
		|term2
		;
		
term2:
		term2 EE term3	{
							if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
								yyerror("semantic error: comparison operator used on non-int value");
							fprintf(yyout,"cmp r%d,r%d\n",$1.reg,$3.reg);
							fprintf(yyout,"je label%d\n",labelCount);
							fprintf(yyout,"mov r%d,0\n",regCount);
							fprintf(yyout,"jmp label%d\n",labelCount+1);
							fprintf(yyout,"label%d:\n",labelCount);
							fprintf(yyout,"mov r%d,1\n",regCount);
							fprintf(yyout,"label%d:\n",labelCount+1);
							strcpy($$.val_type,"bool");
							regcomp=regCount;
							casecomp=regCount;
							$$.reg=regCount;
							regCount=regCount+1;
							labelCount=labelCount+2;
						}
		|term2 NE term3	{
							if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
								yyerror("semantic error: comparison operator used on non-int value");
							fprintf(yyout,"cmp r%d,r%d\n",$1.reg,$3.reg);
							fprintf(yyout,"jne label%d\n",labelCount);
							fprintf(yyout,"mov r%d,0\n",regCount);
							fprintf(yyout,"jmp label%d\n",labelCount+1);
							fprintf(yyout,"label%d:\n",labelCount);
							fprintf(yyout,"mov r%d,1\n",regCount);
							fprintf(yyout,"label%d:\n",labelCount+1);
							strcpy($$.val_type,"bool");
							regcomp=regCount;
							casecomp=regCount;
							$$.reg=regCount;
							regCount=regCount+1;
							labelCount=labelCount+2;
						}
		|term3
		;
		
term3:
		term3 '>' term4	{
							if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
								yyerror("semantic error: comparison operator used on non-int value");
							fprintf(yyout,"cmp r%d,r%d\n",$1.reg,$3.reg);
							fprintf(yyout,"ja label%d\n",labelCount);
							fprintf(yyout,"mov r%d,0\n",regCount);
							fprintf(yyout,"jmp label%d\n",labelCount+1);
							fprintf(yyout,"label%d:\n",labelCount);
							fprintf(yyout,"mov r%d,1\n",regCount);
							fprintf(yyout,"label%d:\n",labelCount+1);
							strcpy($$.val_type,"bool");
							regcomp=regCount;
							casecomp=regCount;
							$$.reg=regCount;
							regCount=regCount+1;
							labelCount=labelCount+2;
						}
		|term3 '<' term4	{
								if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
									yyerror("semantic error: comparison operator used on non-int value");
								fprintf(yyout,"cmp r%d,r%d\n",$1.reg,$3.reg);
								fprintf(yyout,"jb label%d\n",labelCount);
								fprintf(yyout,"mov r%d,0\n",regCount);
								fprintf(yyout,"jmp label%d\n",labelCount+1);
								fprintf(yyout,"label%d:\n",labelCount);
								fprintf(yyout,"mov r%d,1\n",regCount);
								fprintf(yyout,"label%d:\n",labelCount+1);
								strcpy($$.val_type,"bool");
								regcomp=regCount;
								casecomp=regCount;
								$$.reg=regCount;
								regCount=regCount+1;
								labelCount=labelCount+2;
							}
		|term3 GE term4	{
							if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
								yyerror("semantic error: comparison operator used on non-int value");
							fprintf(yyout,"cmp r%d,r%d\n",$1.reg,$3.reg);
							fprintf(yyout,"jae label%d\n",labelCount);
							fprintf(yyout,"mov r%d,0\n",regCount);
							fprintf(yyout,"jmp label%d\n",labelCount+1);
							fprintf(yyout,"label%d:\n",labelCount);
							fprintf(yyout,"mov r%d,1\n",regCount);
							fprintf(yyout,"label%d:\n",labelCount+1);
							strcpy($$.val_type,"bool");
							regcomp=regCount;
							casecomp=regCount;
							$$.reg=regCount;
							regCount=regCount+1;
							labelCount=labelCount+2;
						}
		|term3 LE term4	{
							if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
								yyerror("semantic error: comparison operator used on non-int value");
							fprintf(yyout,"cmp r%d,r%d\n",$1.reg,$3.reg);
							fprintf(yyout,"jbe label%d\n",labelCount);
							fprintf(yyout,"mov r%d,0\n",regCount);
							fprintf(yyout,"jmp label%d\n",labelCount+1);
							fprintf(yyout,"label%d:\n",labelCount);
							fprintf(yyout,"mov r%d,1\n",regCount);
							fprintf(yyout,"label%d:\n",labelCount+1);
							strcpy($$.val_type,"bool");
							regcomp=regCount;
							casecomp=regCount;
							$$.reg=regCount;
							regCount=regCount+1;
							labelCount=labelCount+2;
						}
		|term4
		;
		
term4:
		term4 '+' term5	{
							if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
								yyerror("semantic error: addition operator used on non-int value");
							fprintf(yyout,"add r%d,r%d,r%d\n",regCount,$1.reg,$3.reg);
							strcpy($$.val_type,"int");
							regcomp=regCount;
							casecomp=regCount;
							$$.reg=regCount;
							regCount=regCount+1;
						}
		|term4 '-' term5	{
								if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
									yyerror("semantic error: subtraction operator used on non-int value");
								fprintf(yyout,"sub r%d,r%d,r%d\n",regCount,$1.reg,$3.reg);
								strcpy($$.val_type,"int");
								regcomp=regCount;
								casecomp=regCount;
								$$.reg=regCount;
								regCount=regCount+1;
							}
		|term5
		;
		
term5:
		term5 '*' term6	{
							if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
								yyerror("semantic error: multiplication operator used on non-int value");
							fprintf(yyout,"mul r%d,r%d,r%d\n",regCount,$1.reg,$3.reg);
							strcpy($$.val_type,"int");
							regcomp=regCount;
							casecomp=regCount;
							$$.reg=regCount;
							regCount=regCount+1;
						}
		|term5 '/' term6	{
								if(strcmp($1.val_type,"int")!=0||strcmp($3.val_type,"int")!=0)
									yyerror("semantic error: division operator used on non-int value");
								fprintf(yyout,"div r%d,r%d,r%d\n",regCount,$1.reg,$3.reg);
								strcpy($$.val_type,"int");
								regcomp=regCount;
								casecomp=regCount;
								$$.reg=regCount;
								regCount=regCount+1;
							}
		|term6
		;
		
term6:
		'-' arithmetic_operand	{
									fprintf(yyout,"neg r%d\n",$2.reg);
									strcpy($$.val_type,"int");
									regcomp=$2.reg;
								    casecomp=$2.reg;
									$$.reg=$2.reg;
								}
		|'!' logical_operand	{
									fprintf(yyout,"not r%d\n",$2.reg);
									strcpy($$.val_type,"bool");
									regcomp=$2.reg;
								    casecomp=$2.reg;
									$$.reg=$2.reg;
								}
		|arithmetic_operand
		|logical_operand
		|'-' id_temp	{
							if(strcmp(string_stack_top(&sym_table[$2.index].type_stack),"int")!=0)
								yyerror("semantic error: negation operator used on non-int value");
							fprintf(yyout,"neg r%d\n",$2.reg);
							strcpy($$.val_type,"int");
							regcomp=$2.reg;
							casecomp=$2.reg;
							$$.reg=$2.reg;
						}
		|'!' id_temp	{
							if(strcmp(string_stack_top(&sym_table[$2.index].type_stack),"bool")!=0)
								yyerror("semantic error: NOT operator used on non-bool value");
							fprintf(yyout,"not r%d\n",$2.reg);
							strcpy($$.val_type,"bool");
							regcomp=$2.reg;
							casecomp=$2.reg;
							$$.reg=$2.reg;
						}
		|id_temp
		|'(' expression ')'	{$$.reg=$2.reg;
							regcomp=$2.reg;
							casecomp=$2.reg;
							strcpy($$.val_type,$2.val_type);
							}
		|'-' '(' expression ')'	{
									if(strcmp($3.val_type,"int")!=0)
										yyerror("semantic error: negation operator used on non-int value");
									strcpy($$.val_type,"int");
									regcomp=$3.reg;
								    casecomp=$3.reg;
									$$.reg=$3.reg;
									strcpy($$.val_type,"int");
								}
		|'!' '(' expression ')'	{
									if(strcmp($3.val_type,"bool")!=0)
										yyerror("semantic error: NOT operator used on non-bool value");
									strcpy($$.val_type,"bool");
									regcomp=$3.reg;
								    casecomp=$3.reg;
									$$.reg=$3.reg;
									strcpy($$.val_type,"bool");
								}
		|function_call_temp
		|'-' function_call_temp	{
									if(strcmp(func_table[$2.index].return_type,"int")!=0)
										yyerror("semantic error: negation operator used on non-int value");
									fprintf(yyout,"neg r%d\n",$2.reg);
									strcpy($$.val_type,"int");
									regcomp=$2.reg;
								    casecomp=$2.reg;
									$$.reg=$2.reg;
								}
		|'!' function_call_temp	{
									if(strcmp(func_table[$2.index].return_type,"bool")!=0)
										yyerror("semantic error: negation operator used on non-bool value");
									fprintf(yyout,"neg r%d\n",$2.reg);
									strcpy($$.val_type,"bool");
									regcomp=$2.reg;
								    casecomp=$2.reg;
									$$.reg=$2.reg;
								}
		|error arithmetic_operand	{yyerror("syntax error: illegal operator");}
		|error logical_operand	{yyerror("syntax error: illegal operator");}
		|error '(' expression ')'	{yyerror("syntax error: expected operator, control statement or function identifier");}
		|error id_temp	{yyerror("syntax error: illegal operator");}
		|error function_call_temp	{yyerror("syntax error: illegal operator");}
		;
		
arithmetic_operand:
					int_value	{
									fprintf(yyout,"mov r%d,%d\n",regCount,$1.int_val);
									strcpy($$.val_type,"int");
									regcomp=regCount;
								    casecomp=regCount;
									$$.reg=regCount;
									regCount=regCount+1;
								}
					;

logical_operand:
					bool_value	{
									fprintf(yyout,"mov r%d,%d\n",regCount,$1.int_val);
									strcpy($$.val_type,"bool");
									regcomp=regCount;
								    casecomp=regCount;
									$$.reg=regCount;
									regCount=regCount+1;
								}
					;

id_temp:
			ID	{
					current_index=get_sym_index($1.string_val);
					if(int_stack_top(&sym_table[current_index].initialized_stack)==0)
						yyerror(get_error_msg("semantic error: identifier '",$1.string_val,"' is used without being initialized"));
					int_stack_pop(&sym_table[current_index].used_stack);
					int_stack_push(&sym_table[current_index].used_stack,1);
					fprintf(yyout,"mov r%d,%s\n",regCount,$1.string_val);
					strcpy($$.val_type,string_stack_top(&sym_table[current_index].type_stack));
					$$.index=current_index;
					$$.reg=regCount;
					regcomp=regCount;
					casecomp=regCount;
					regCount=regCount+1;
				}
			;
			
function_call_temp:
					function_call	{
										current_index=get_func_index($1.string_val);
										fprintf(yyout,"mov r%d,r%d\n",regCount,func_table[current_index].returned_reg);
										strcpy($$.val_type,func_table[current_index].return_type);
										$$.index=current_index;
										$$.reg=regCount;
										regcomp=regCount;
										casecomp=regCount;
										regCount=regCount+1;
									}
					;
			
if_then_else:
				main_part_of_if_then_else optional1_of_if_then_else optional2_of_if_then_else	{
																									fprintf(yyout,"if_label%d:\n",int_stack_pop(&if_stack));
																								}
				;
				
main_part_of_if_then_else:
							if_part complex_statement_body	{
																fprintf(yyout,"jmp if_label%d\n",int_stack_top(&if_stack));
																fprintf(yyout,"label%d:\n",$1.label);
															}
							;
				
if_part:
		IF '(' expression ')'	{
									int_stack_push(&if_stack,if_labelCount);
									if_labelCount=if_labelCount+1;
									fprintf(yyout,"cmp r%d,1\n",$3.reg);
									fprintf(yyout,"jne label%d\n",labelCount);
									$$.label=labelCount;
									labelCount=labelCount+1;
								}
		|IF error expression ')'	{yyerror("syntax error: expected '('");}
		|IF '(' error ')'	{yyerror("syntax error: expected expression");}
		;
		
optional1_of_if_then_else:
							optional1_of_if_then_else elseif_part complex_statement_body	{
																								fprintf(yyout,"jmp if_label%d\n",int_stack_top(&if_stack));
																								fprintf(yyout,"label%d:\n",$2.label);
																							}
							|
							;
						
elseif_part:
			ELSEIF '(' expression ')'	{
											fprintf(yyout,"cmp r%d,1\n",$3.reg);
											fprintf(yyout,"jne label%d\n",labelCount);
											$$.label=labelCount;
											labelCount=labelCount+1;
										}
			;

optional2_of_if_then_else:
							else_part complex_statement_body
							|
							;
			
else_part:
			ELSE
			;

while_loop:
			WHILE while_begin '(' expression ')' while_mid complex_statement_body while_end end_break
			{
								
								
			}
			|WHILE while_begin error expression ')' while_mid complex_statement_body while_end end_break	{yyerror("syntax error: expected '('");}
			|WHILE while_begin '(' error ')' while_mid complex_statement_body while_end end_break	{yyerror("syntax error: expected expression");}
			|WHILE while_begin '(' expression error while_mid complex_statement_body while_end end_break	{yyerror("syntax error: expected ')'");}
			;
while_begin: {
					fprintf(yyout,"l%d:\n",labeljmp);
					whilelabels[whileiterator]=labeljmp;
					whilebreaks[whilebreakiterator]=1;
					whilebreakiterator++;
					whileiterator=whileiterator+1;
					labeljmp=labeljmp+1;
					
				};
while_end : {
                                                    whileiterator=whileiterator-1;
													whileiteratorout=whileiteratorout-1;
													whilebreakiterator--;
													whilebreaks[whilebreakiterator]=0;
													
					fprintf(yyout,"jmp l%d\n",whilelabels[whileiterator]);
					fprintf(yyout,"lout%d:\n",whilelabelsout[whileiteratorout]);
													
												//	whileiterator=whileiterator-1;
												//	whileiteratorout=whileiteratorout-1;
													
					
					
					};
while_mid: {
				              fprintf(yyout,"cmp r%d,1\n",regcomp);
							  whilelabelsout[whileiteratorout]=labelout;
							  fprintf(yyout,"je lmid%d\n",whilelabelsout[whileiteratorout]+1);
								fprintf(yyout,"jmp lout%d\n",whilelabelsout[whileiteratorout]);
								fprintf(yyout,"lmid%d:\n",whilelabelsout[whileiteratorout]+1);
								labelout=labelout+2;
								whileiteratorout=whileiteratorout+1;
								
								
								
								

			};
			
do_while_loop:
				do_while_begin DO complex_statement_body WHILE '(' expression ')' do_while_end end_break
				|do_while_begin DO complex_statement_body error '(' expression ')' do_while_end end_break	{yyerror("syntax error: expected 'while'");}
				|do_while_begin DO complex_statement_body WHILE '(' error ')' do_while_end end_break	{yyerror("syntax error: expected expression");}
				;
				
do_while_begin:
					{
						fprintf(yyout,"dowhilelabel%d:\n",dolabel);
						dowhilelabels[doiterator]=dolabel;
						doiterator++;
						dolabel++;
						dowhilebreaks[dowhilebreakiterator]=1;
						dowhilebreakiterator++;
					}

;				
				
do_while_end:
				{
					dowhilebreakiterator--;
					dowhilebreaks[dowhilebreakiterator]=0;
						
					doiterator--;
					fprintf(yyout,"cmp r%d,1\n",regcomp);
					fprintf(yyout,"je dowhilelabel%d\n",dowhilelabels[doiterator]);
				}
;
for_loop:
			FOR '('  for_init ';' init_label expression stat_jump ';' increment_label for_increment jmp_init ')'  stat_label complex_statement_body  for_leave end_break
			|error '('  for_init ';' init_label expression stat_jump ';' increment_label for_increment jmp_init ')'  stat_label complex_statement_body  for_leave end_break	{yyerror("syntax error: expected 'for'");}
			|FOR error for_init ';' init_label expression stat_jump ';' increment_label for_increment jmp_init ')'  stat_label complex_statement_body  for_leave end_break	{yyerror("syntax error: expected '('");}
			;
			
init_label:{
				fprintf(yyout,"forlabel%d:\n",foriterator);
				forbreaks[forbreakiterator]=1;
				forbreakiterator++;
				
				
			};
stat_jump :{
				fprintf(yyout,"cmp r%d ,1\n",regcomp);
				fprintf(yyout,"je statlabel%d\n",forstat);
				fprintf(yyout,"jmp forout%d\n",foroutt);
				forlabelsout[foriteratorout]=foroutt;
				foriteratorout++;
				foroutt++;
				
			};
stat_label:{
				fprintf(yyout,"statlabel%d:\n",forstat);
				forstat++;
			};
for_leave:{
				incrementiterator--;
				foriteratorout--;
				forbreakiterator--;
				forbreaks[forbreakiterator]=0;
				
				fprintf(yyout,"jmp increment%d\n",forincrements[incrementiterator]);
				fprintf(yyout,"forout%d:\n",forlabelsout[foriteratorout]);
		};
increment_label: {
						fprintf(yyout,"increment%d:\n",incc);
						forincrements[incrementiterator]=incc;
						incc++;
						incrementiterator++;
						
					
};
jmp_init: {
				fprintf(yyout,"jmp forlabel%d\n",foriterator);
				foriterator++;
		
};
for_init:
			declaration_temp
			|assignment_list
			|
			;
			
assignment_list:
				assignment rest_of_assignment_list
				;
				
rest_of_assignment_list:
						',' assignment rest_of_assignment_list
						|
						;
						
for_increment:
				assignment_list
				;
				

end_break :{
				breakiterator--;		
				fprintf(yyout,"breaklabel%d:\n",breaklabels[breakiterator]);
				
			};
case_end_break:

{
	fprintf(yyout,"casebreaklabel%d:\n",casebreaklabel);
	casebreaklabel++;
};
switch_case:
			switch_begin '{' cases  default_part '}' case_end_break
			;
			
switch_begin :SWITCH '(' expression ')' {
															fprintf(yyout,"mov rswitch,r%d\n",casecomp);
			
								}
				|SWITCH error expression ')'
				|SWITCH '(' error ')'
								
case_begin: CASE  expression {
															fprintf(yyout,"cmp rswitch,r%d\n",casecomp);
															fprintf(yyout,"jne case%d\n",caselabel);
															caselabels[caseiterator]=caselabel;
															caseiterator++;
															caselabel++;
			
			}
			
	BREAK_begin :  {
					fprintf(yyout,"jmp casebreaklabel%d\n",casebreaklabel);
					
				
				};
case_label: {
				caseiterator--;
				fprintf(yyout,"case%d:\n",caselabels[caseiterator]);
				
			}
cases:
		//CASE expression ':' statements  cases 
		//|
		  case_begin ':' statements BREAK_begin case_label cases
		
		|
		;
		
default_part:
				DEFAULT ':' statements
				;
				
function:
			function_begin '(' parameter_declarations ')' parameters_passing block	{
																						if(returned==0)
																							yyerror(get_error_msg("semantic error: function '",$2.string_val,"' doesn't return a value"));
																						fprintf(yyout,"end proc %s\n\n",current_func);
																					}
			|function_begin error parameter_declarations ')' parameters_passing block	{yyerror("syntax error: expected '('");}
			|function_begin '(' parameter_declarations error parameters_passing block	{yyerror("syntax error: expected ')'");}
			;

function_begin:
				return_type ID	{
									if(strcmp($1.string_val,"void")!=0)
										returned=0;
									else
										returned=1;
									current_index=get_func_index($2.string_val);
									if(strcmp(func_table[current_index].return_type,"")!=0)
										yyerror(get_error_msg("semantic error: function '",$2.string_val,"' is defined more than once"));
									else
									{
										strcpy(func_table[current_index].id,$2.string_val);
										strcpy(func_table[current_index].return_type,$1.string_val);
										func_table[current_index].first_param_reg=regCount;
										func_table[current_index].num_of_params=0;
										fprintf(yyout,"proc %s\n",$2.string_val);
										strcpy(current_func,$2.string_val);
										int_stack_init(&scope_stack);
										scopeCount=0;
									}
								}
				;
			
return_type:
				TYPE
				|VOID
				;
			
parameter_declarations:
						rest_of_declarations parameter_declaration
						|
						;
				
rest_of_declarations:
						rest_of_declarations parameter_declaration ','
						|
						;
						
parameter_declaration:
						TYPE ID	{
									current_index=get_sym_index($2.string_val);
									if(strcmp(sym_table[current_index].func,current_func)==0&&int_stack_empty(&sym_table[current_index].scope_stack)!=0)
									{
										if(int_stack_top(&sym_table[current_index].scope_stack)==int_stack_top(&scope_stack))
											yyerror(get_error_msg("semantic error: identifier '",$1.string_val,"' is declared more than once in the same scope"));
									}
									else
									{
										strcpy(sym_table[current_index].id,$2.string_val);
										string_stack_push(&sym_table[current_index].type_stack,$1.string_val);
										strcpy(sym_table[current_index].func,current_func);
										int_stack_push(&sym_table[current_index].scope_stack,1);
										int_stack_push(&sym_table[current_index].initialized_stack,1);
										int_stack_push(&sym_table[current_index].constant_stack,0);
										int_stack_push(&sym_table[current_index].used_stack,0);
										fprintf(yyout,"push %s\n",$2.string_val);
										current_index=get_func_index(current_func);
										add_string_to_list(func_table[current_index].param_list,$2.string_val);
										add_string_to_list(func_table[current_index].param_types_list,$1.string_val);
										func_table[current_index].num_of_params=func_table[current_index].num_of_params+1;
									}
								}
						;
						
parameters_passing:	{
						current_index=get_func_index(current_func);
						for(int i=0;i<func_table[current_index].num_of_params;i++)
							fprintf(yyout,"mov %s,r%d\n",func_table[current_index].param_list[i],func_table[current_index].first_param_reg+i);
						regCount=regCount+func_table[current_index].num_of_params;
						if(strcmp(func_table[current_index].return_type,"void")!=0)
						{
							func_table[current_index].returned_reg=regCount;
							regCount=regCount+1;
						}
					}
					;
					
return_from_func:
					RETURN expression	{
											current_index=get_func_index(current_func);
											if(strcmp(func_table[current_index].return_type,$2.val_type)!=0)
													yyerror("type mismatch between returned value and function return type");
											else
											{
												fprintf(yyout,"mov r%d,r%d\n",func_table[current_index].returned_reg,$2.reg);
												for(int i=0;i<1024;i++)
												{
													if(int_stack_empty(&sym_table[i].scope_stack)==0&&strcmp(sym_table[i].func,current_func)==0)
													{
														if(int_stack_top(&sym_table[i].scope_stack)==int_stack_top(&scope_stack))
															fprintf(yyout,"pop %s\n",sym_table[i].id);
													}
												}
												fprintf(yyout,"ret\n");
											}
											returned=1;
										}
					|RETURN	{
								if(strcmp(func_table[current_index].return_type,"void")!=0)
									yyerror("no return value specified");
								else
									fprintf(yyout,"ret\n");
								returned=1;
							}
					;
						
function_call:
				called_func '(' parameters ')'	{
													if(passedParamCount>func_table[current_index].num_of_params)
														yyerror("semantic error: too many parameters passed to function");
													else if(passedParamCount<func_table[current_index].num_of_params)
														yyerror("semantic error: too few parameters passed to function");
													else
													{
														strcpy($$.string_val,$1.string_val);
														fprintf(yyout,"call %s\n",$1.string_val);
													}
												}
				;
				
called_func:
			ID	{
					current_index=get_func_index($1.string_val);
					if(strcmp(func_table[current_index].return_type,"")==0)
						yyerror(get_error_msg("semantic error: function '",$1.string_val,"' is undefined"));
					else
					{
						strcpy(calling_func,$1.string_val);
						passedParamCount=0;
						strcpy($$.string_val,$1.string_val);
					}
				}
			;
				
parameters:
			rest_of_parameters expression	{
												current_index=get_func_index(calling_func);
												if(passedParamCount<func_table[current_index].num_of_params)
												{
													if(strcmp($2.val_type,func_table[current_index].param_types_list[passedParamCount])!=0)
														yyerror("semantic error: type mismatch in parameters passed to function");
												}
												else
													fprintf(yyout,"mov r%d,r%d\n",func_table[current_index].first_param_reg+passedParamCount,$2.reg);
												passedParamCount=passedParamCount+1;
											}
			|
			;
			
rest_of_parameters:
					rest_of_parameters expression ','	{
															current_index=get_func_index(calling_func);
															if(passedParamCount<func_table[current_index].num_of_params)
															{
																if(strcmp($2.val_type,func_table[current_index].param_types_list[passedParamCount])!=0)
																	yyerror("semantic error: type mismatch in parameters passed to function");
															}
															else
																fprintf(yyout,"mov r%d,r%d\n",func_table[current_index].first_param_reg+passedParamCount,$2.reg);
															passedParamCount=passedParamCount+1;
														}
					|
					;

%%

void yyerror(char *s) {
    fprintf(stderr, "line %d: %s\n", yylineno, s);
}

void int_stack_init(struct int_stack *s)
{
	s->top=-1;
}

void int_stack_push(struct int_stack *s, int val)
{
	s->top=s->top+1;
	s->arr[s->top]=val;
}

int int_stack_pop(struct int_stack *s)
{
	int returned=s->arr[s->top];
	s->arr[s->top]=-1;
	s->top=s->top-1;
	return returned;
}

int int_stack_top(struct int_stack *s)
{
	return s->arr[s->top];
}

int int_stack_empty(struct int_stack *s)
{
	if(s->top==-1)
		return 1;
	return 0;
}

void string_stack_init(struct string_stack *s)
{
	s->top=-1;
}

void string_stack_push(struct string_stack *s, char *val)
{
	s->top=s->top+1;
	strcpy(s->arr[s->top],val);
}

char* string_stack_pop(struct string_stack *s)
{
	char *returned=malloc(sizeof(char)*1024);
	strcpy(returned,s->arr[s->top]);
	strcpy(s->arr[s->top],"");
	s->top=s->top-1;
	return returned;
}

char* string_stack_top(struct string_stack *s)
{
	return s->arr[s->top];
}

int string_stack_empty(struct string_stack *s)
{
	if(s->top==-1)
		return 1;
	return 0;
}

void init_string_list(char **param_list)
{
	for(int i=0;i<1024;i++)
		param_list[i]=NULL;
}

void add_string_to_list(char **param_list, char* addedParam)
{
	int i=0;
	while(param_list[i]!=NULL)
		i=i+1;
	param_list[i]=malloc(sizeof(char)*1024);
	strcpy(param_list[i],addedParam);
}

void init_sym_table()
{
	for(int i=0;i<1024;i++)
	{
		strcpy(sym_table[i].id,"");
		string_stack_init(&sym_table[i].type_stack);
		int_stack_init(&sym_table[i].scope_stack);
		int_stack_init(&sym_table[i].constant_stack);
		int_stack_init(&sym_table[i].initialized_stack);
		int_stack_init(&sym_table[i].used_stack);
	}
}

void init_func_table()
{
	for(int i=0;i<1024;i++)
	{
		strcpy(func_table[i].id,"");
		strcpy(func_table[i].return_type,"");
		func_table[i].first_param_reg=0;
		func_table[i].num_of_params=0;
		func_table[i].returned_reg=0;
		init_string_list(func_table[i].param_list);
		init_string_list(func_table[i].param_types_list);
	}
}

int get_sym_index(char *id)
{
	for(int i=0;i<1024;i++)
	{
		if(strcmp(sym_table[i].id,id)==0||strcmp(sym_table[i].id,"")==0)
			return i;
	}
	return -1;
}

int get_func_index(char *id)
{
	for(int i=0;i<1024;i++)
	{
		if(strcmp(func_table[i].id,id)==0||strcmp(func_table[i].id,"")==0)
			return i;
	}
	return -1;
}

char* get_error_msg(char* part1, char* param, char* part2)
{
	char *msg=malloc(sizeof(char)*1024);
	strcpy(msg,part1);
	strcat(msg,param);
	strcat(msg,part2);
	return msg;
}

int main(void) {
	init_sym_table();
	init_func_table();
	int_stack_init(&if_stack);
	for (int i=0;i<255;i++)
	{
		whilebreaks[i]=0;
		forbreaks[i]=0;
		//switchbreaks[i]=0;
		dowhilebreaks[i]=0;
	}
    yyin = fopen("input.txt", "r");
	yyout = fopen("output.txt", "w");
    yyparse();
    fclose(yyin);
    fclose(yyout);
    return 0;
}