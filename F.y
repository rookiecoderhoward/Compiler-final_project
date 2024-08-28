%{
    #define SIZE 777
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdbool.h>
    #include <math.h>
    extern int yylex(void);

    int temp_num = 0;
    int has_first_eqnum = 0, is_equal = 0, cur_eqnum;

    char* TF[] = {"#t", "#f"};

    typedef struct node_default {
        /* number, check in func or not, check is int or boolean operation */
        int data, is_in_func, is_boolean; 
        char* node_type;
        char* id;
        /* type "if" --- mid: first condition, right: second condition */
        struct node_default *left, *mid, *right;
    } Node;

    // create new node
    Node *create_node(Node *left, Node *right, char* type, int is_boolean);

    Node *root = NULL;
    Node *func_stack[SIZE];

    typedef struct buffer {
        int data, is_in_func;
        char* id;
    } Buffer;

    int var_ct = 0, param_ct = 0, func_ct = 0;
    int borrow_space = 0;
    Buffer param_stack[SIZE]; // in scope parameter
    Buffer var_stack[SIZE]; // out scope

    void AST_traversal(Node *node);
    void add_op(Node *node); // might encounter exps
    void sub_op(Node *node);
    void mul_op(Node *node); // might encounter exps
    void div_op(Node *node);
    void mod_op(Node *node);
    int bool_op(int rval, int lval); // set - greater:1, smaller:0
    void equal_op(Node *node);
    void and_op(Node *node);
    void or_op(Node *node);
    void smaller_op(Node *node);
    void not_op(Node *node);

    void assign_var_data(Node *node);

    void print_syntax_error();
    void print_type_error();
    void yyerror(const char *error_msg);
%}

%union {
    int ival, boolean;
    char* word;
    struct node_default *node_val;
}

%start program

%token PRINT_NUM PRINT_BOOL ADD SUB MUL DIV GREATER SMALLER EQUAL MOD AND OR NOT IF FUNC DEF 
%token <ival> NUMBER
%token <boolean> BOOL
%token <word> WORD

%type <node_val> program stmts stmt print_stmt exp primary_exp def_stmt variable
%type <node_val> plus minus multiply divide modules greater smaller equal if_exp
%type <node_val> num_op logical_op and_op or_op not_op
%type <node_val> func_exp fun_ids ids fun_body func_call param func_name

%%

program         : stmts                         {root = $1;}
                ;

stmts           : stmt stmts                    {$$ = create_node($1, $2, "statement", 0);}
                | stmt                          {$$ = $1;}
                ;

stmt            : exp                           {$$ = $1;}
                | def_stmt                      {$$ = $1;}
                | print_stmt                    {$$ = $1;}
                ;

print_stmt      : '(' PRINT_NUM exp ')'         {$$ = create_node($3, NULL, "print_num", 0);}
                | '(' PRINT_BOOL exp ')'        {$$ = create_node($3, NULL, "print_bool", 0);}
                ;

exp             : NUMBER                        {$$ = create_node(NULL, NULL, "number", 0); $$->data = $1;}
                | BOOL                          {$$ = create_node(NULL, NULL, "bool", 1); $$->data = $1;}
                | variable                      {$$ = $1;}
                | num_op                        {$$ = $1;}
                | logical_op                    {$$ = $1;}
                | func_exp                      {$$ = $1;}
                | func_call                     {$$ = $1;}
                | if_exp                        {$$ = $1;}
                ;

num_op          : plus                          {$$ = $1;}
                | minus                         {$$ = $1;}
                | multiply                      {$$ = $1;}
                | divide                        {$$ = $1;}
                | modules                       {$$ = $1;}
                | greater                       {$$ = $1;}
                | smaller                       {$$ = $1;}
                | equal                         {$$ = $1;}
                ;

plus            : '(' ADD exp primary_exp ')'   {$$ = create_node($3, $4, "add", 0);}
                ;
minus           : '(' SUB exp exp ')'           {$$ = create_node($3, $4, "sub", 0);}
                ;
multiply        : '(' MUL exp primary_exp ')'   {$$ = create_node($3, $4, "mul", 0);}
                ;
divide          : '(' DIV exp exp ')'           {$$ = create_node($3, $4, "div", 0);}
                ;
modules         : '(' MOD exp exp ')'           {$$ = create_node($3, $4, "mod", 0);}
                ;
greater         : '(' GREATER exp exp ')'       {$$ = create_node($3, $4, "greater", 1);}
                ;
smaller         : '(' SMALLER exp exp ')'       {$$ = create_node($3, $4, "smaller", 1);}
                ;
equal           : '(' EQUAL exp primary_exp ')' {$$ = create_node($3, $4, "equal", 1);}
                ;

primary_exp     : exp primary_exp               {$$ = create_node($1, $2, "exps", 0);}
                | exp                           {$$ = $1;}
                ;

logical_op      : and_op                        {$$ = $1;}
                | or_op                         {$$ = $1;}
                | not_op                        {$$ = $1;}
                ;

and_op          : '(' AND exp primary_exp ')'   {$$ = create_node($3, $4, "and", 1);}
                ;
or_op           : '(' OR exp primary_exp ')'    {$$ = create_node($3, $4, "or", 1);}
                ;
not_op          : '(' NOT exp ')'               {$$ = create_node($3, NULL, "not", 1);}
                ;

def_stmt        : '(' DEF variable exp ')'      {$$ = create_node($3, $4, "def", 0);}
                ;

variable        : WORD                          {$$ = create_node(NULL, NULL, "var", 0); $$->id = $1;}
                ;

if_exp          : '(' IF exp exp exp ')'        {$$ = create_node($3, $5, "if", 0); $$->mid = $4;} 
                ;

func_exp        : '(' FUNC fun_ids fun_body ')' {$$ = create_node($3, $4, "function", 0);}
                ;

fun_ids         : '(' ids ')'                   {$$ = $2;}
                ;
ids             : ids variable                  {$$ = create_node($1, $2, "exps", 0);}
                |                               {$$ = create_node(NULL, NULL, "no_param", 0);}
                ;

fun_body        : exp                           {$$ = $1;}
                ;

func_call       : '(' func_exp param ')'        {$$ = create_node($2, $3, "func_call", 0);}
                | '(' func_name param ')'       {$$ = create_node($2, $3, "def_and_func_call", 0);}
                ;

param           : exp param                     {$$ = create_node($1, $2, "exps", 0);}
                |                               {$$ = create_node(NULL, NULL, "no_param", 0);}
                ;

func_name       : WORD                          {$$ = create_node(NULL, NULL, "func_name", 0); $$->id = $1;}
                ;

%%

void AST_traversal(Node *node) {
    // check is NULL or not
    if (!node) return;
    // print_num
    if (!strcmp(node->node_type, "print_num")) {
        AST_traversal(node->left);
        printf("%d\n", node->left->data);
    }
    // print_bool
    else if (!strcmp(node->node_type, "print_bool")) {
        AST_traversal(node->left);
        if (node->left->data) printf("%s\n", TF[0]);
        else printf("%s\n", TF[1]);
    }
    // plus
    else if (!strcmp(node->node_type, "add")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        temp_num = 0;
        add_op(node);
        node->data = temp_num;
        if (node->left->is_boolean || node->right->is_boolean) {
            print_type_error();
        }
    }
    // minus
    else if (!strcmp(node->node_type, "sub")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        sub_op(node);
        if (node->left->is_boolean || node->right->is_boolean) {
            print_type_error();
        }
    }
    // multiply
    else if (!strcmp(node->node_type, "mul")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        temp_num = 1;
        mul_op(node);
        node->data = temp_num;
        if (node->left->is_boolean || node->right->is_boolean) {
            print_type_error();
        }
    }
    // divide
    else if (!strcmp(node->node_type, "div")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        div_op(node);
        if (node->left->is_boolean || node->right->is_boolean) {
            print_type_error();
        }
    }
    // modules
    else if (!strcmp(node->node_type, "mod")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        mod_op(node);
        if (node->left->is_boolean || node->right->is_boolean) {
            print_type_error();
        }
    }
    // greater
    else if (!strcmp(node->node_type, "greater")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        node->is_boolean = 1; // make sure is boolean type
        if (node->left && node->right) {
            if (bool_op(node->left->data, node->right->data)) {
                node->data = 1;
            }
            else node->data = 0;
        }
    }
    // smaller
    else if (!strcmp(node->node_type, "smaller")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        node->is_boolean = 1; // make sure is boolean type
        if (node->left && node->right) {
            if (!bool_op(node->left->data, node->right->data)) {
                node->data = 1;
            }
            else node->data = 0;
        }
    }
    // equal
    else if (!strcmp(node->node_type, "equal")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        node->is_boolean = 1; // make sure is boolean type
        has_first_eqnum = 0, is_equal = 1;
        equal_op(node);
        node->data = is_equal;
    }
    // and
    else if (!strcmp(node->node_type, "and")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        node->is_boolean = 1; // make sure is boolean type
        temp_num = 1;
        and_op(node);
        node->data = temp_num;
    }
    // or
    else if (!strcmp(node->node_type, "or")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        node->is_boolean = 1; // make sure is boolean type
        temp_num = 0;
        or_op(node);
        node->data = temp_num;
    }
    // not
    else if (!strcmp(node->node_type, "not")) {
        AST_traversal(node->left); // right is NULL
        node->is_boolean = 1; // make sure is boolean type
        not_op(node);
    }
    // if
    else if (!strcmp(node->node_type, "if")) {
        AST_traversal(node->left);
        AST_traversal(node->mid);
        AST_traversal(node->right);
        // first_condition selected
        if (node->left->data) {
            node->data = node->mid->data;
            node->is_boolean = node->mid->is_boolean == 1 ? 1 : 0;
        } 
        // second_condition selected
        else {
            node->data = node->right->data;
            node->is_boolean = node->right->is_boolean == 1 ? 1 : 0;
        }
    }
    // define
    else if (!strcmp(node->node_type, "def")) {
        // case 1 : def function
        if (!strcmp(node->right->node_type, "function")) {
            // function no parameter
            if (!strcmp(node->right->left->node_type, "no_param")) {
                var_stack[var_ct].is_in_func = 0;
                var_stack[var_ct].id = node->left->id;
                // e.g. (define foo (fun () 0))
                var_stack[var_ct].data = node->right->right->data;
                var_ct++;
            }
            // function has parameter
            else {
                func_stack[func_ct] = node;
                func_ct++;
            }
        }
        // case 2 : def var (def x 1)
        else {
            AST_traversal(node->left);
            AST_traversal(node->right);
            var_stack[var_ct].data = node->right->data, var_stack[var_ct].id = node->left->id;
            var_ct++;
        }
    }
    // search and assign var
    else if (!strcmp(node->node_type, "var")) {
        assign_var_data(node);
    }
    // function
    else if (!strcmp(node->node_type, "function")) {
        AST_traversal(node->left);
        AST_traversal(node->right);
        node->is_boolean = node->right->is_boolean == 1 ? 1 : 0;
    }
    // func_call
    else if (!strcmp(node->node_type, "func_call")) {
        ;
    }
    // def_and_func_call
    else if (!strcmp(node->node_type, "def_and_func_call")) {
       ;
    }
    // stmts, exps
    else {
        AST_traversal(node->left);
        AST_traversal(node->right);
    }
}

void add_op(Node *node) {
    Node *cur;
    if (node->left) {
        if (node->left->is_boolean) {
            print_type_error();
        }
        // stmts : has more numbers (e.g. + 1 2 3 4)
        if (!strcmp(node->left->node_type, "exps")) {
            cur = node->left;
            add_op(cur);
        }
        else temp_num += node->left->data;
    }
    if (node->right) {
        if (node->right->is_boolean) {
            print_type_error();
        }
        // stmts : has more numbers (e.g. + 1 2 3 4)
        if (!strcmp(node->right->node_type, "exps")) {
            cur = node->right;
            add_op(cur);
        }
        else temp_num += node->right->data;
    }
    return;
}

void sub_op(Node *node) {
    if (node->left && node->right) {
        node->data = node->left->data - node->right->data;
    }
    return;
}

void mul_op(Node *node) {
    Node *cur;
    if (node->left) {
        if (node->left->is_boolean) {
            print_type_error();
        }
        // stmts : has more numbers (e.g. * 1 2 3 4)
        if (!strcmp(node->left->node_type, "exps")) {
            cur = node->left;
            mul_op(cur);
        }
        else temp_num *= node->left->data;
    }
    if (node->right) {
        if (node->right->is_boolean) {
            print_type_error();
        }
        // stmts : has more numbers (e.g. * 1 2 3 4)
        if (!strcmp(node->right->node_type, "exps")) {
            cur = node->right;
            mul_op(cur);
        }
        else temp_num *= node->right->data;
    }
    return;
}

void div_op(Node *node) {
    if (node->left && node->right) {
        node->data = node->left->data / node->right->data;
    }
    return;
}

void mod_op(Node *node) {
    if (node->left && node->right) {
        node->data = node->left->data % node->right->data;
    }
    return;
}

// set - greater:1, smaller:0
int bool_op(int rval, int lval) {
    if (rval > lval) return 1;
    else return 0;
}

void equal_op(Node *node) {
    Node *cur;
    if (node->left) {
        if (!strcmp(node->left->node_type, "exps")) {
            cur = node->left;
            equal_op(cur);
        }
        else {
            if (!has_first_eqnum) {
                has_first_eqnum = 1;
                cur_eqnum = node->left->data;
            }
            else {
                is_equal = node->left->data == cur_eqnum ? is_equal : 0;
            }
        }
    }
    if (node->right) {
        if (!strcmp(node->right->node_type, "exps")) {
            cur = node->right;
            equal_op(cur);
        }
        else {
            if (!has_first_eqnum) {
                has_first_eqnum = 1;
                cur_eqnum = node->right->data;
            }
            else {
                is_equal = node->right->data == cur_eqnum ? is_equal : 0;
            }
        }
    }
    return;
}

void and_op(Node *node) {
    Node *cur;
    if (node->left) {
        if (!strcmp(node->left->node_type, "exps")) {
            cur = node->left;
            and_op(cur);
        }
        else temp_num &= node->left->data;
    }
    if (node->right) {
        if (!strcmp(node->right->node_type, "exps")) {
            cur = node->right;
            and_op(cur);
        }
        else temp_num &= node->right->data;
    }
    return;
}

void or_op(Node *node) {
    Node *cur;
    if (node->left) {
        if (!strcmp(node->left->node_type, "exps")) {
            cur = node->left;
            or_op(cur);
        }
        else temp_num |= node->left->data;
    }
    if (node->right) {
        if (!strcmp(node->right->node_type, "exps")) {
            cur = node->right;
            or_op(cur);
        }
        else temp_num |= node->right->data;
    }
    return;
}

void not_op(Node *node) {
    node->data = !node->left->data;
    return;
}

void assign_var_data(Node *node) {
    int i;
    // search the data of aim defined var
    for (i = 0; i < var_ct; i++) {
        if (!strcmp(var_stack[i].id, node->id) && var_stack[i].is_in_func == node->is_in_func) {
            node->data = var_stack[i].data;
            break;
        }
    }
    return;
}

// create new node
Node *create_node(Node *left, Node *right, char* type, int is_boolean) {
    Node *temp = (Node *)malloc(sizeof(Node));
    temp->data = 0, temp->is_in_func = 0, temp->is_boolean = is_boolean;
    temp->node_type = type;
    temp->id = "";
    temp->left = left, temp->mid = NULL, temp->right = right;
    return temp;
}

void yyerror(const char *error_msg) {
    fprintf(stderr, "%s\n", error_msg);
}

void print_syntax_error() {
    printf("syntax error\n");
    exit(1);
}

void print_type_error() {
    printf("Type error!\n");
    exit(1);
}

int main(void) {
    yyparse();
    AST_traversal(root);
    return 0;
}

