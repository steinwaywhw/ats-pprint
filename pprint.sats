staload "ats-utils/list.sats"


(* datatype *)

abstype doc


(* Primitives *)

fun {a:t@ype} primitive (a): doc  (* Turn a primitive typed value into a doc *)


(* Basic combinators *)

fun emp       (): doc                   (* empty document *)

fun line      (): doc                   (* a new line, but may be replaced by space if grouped *)
fun linebreak (): doc                   (* a new line, but may be replaced by empty if grouped *)
fun softline  (): doc                   (* group (line ()), either line or space *)
fun softbreak (): doc                   (* group (linebreak ()), either line or empty *)

fun nest      (doc, int): doc           (* nested doc *)
fun group     (doc): doc                (* try to replace newlines with spaces if the doc fits in one line *)


(* Operators *)

fun cat            (doc, doc): doc  (* concat docs directly *)

fun catBySpace     (doc, doc): doc  (* concat docs sep by space *)
fun catByLine      (doc, doc): doc  (* concat docs sep by line *)
fun catBySoftline  (doc, doc): doc  (* concat docs sep by softline *)
fun catByBreak     (doc, doc): doc  (* concat docs sep by linebreak *)
fun catBySoftbreak (doc, doc): doc  (* concat docs sep by softbreak *)

infixr (+ +1) <:>  // cat x and y, <>
infixr (+ +1) <+>  // cat x and space and y, <+>
infixr (+)    <|>  // cat x and line and y, <$>
infixr (+)    </>  // cat x and softline and y, </>
infixr (+)    <|+> // cat x and linebreak and y, <$$>
infixr (+)    </+> // cat x and softbreak and y, <//>

overload <:>  with cat
overload <+>  with catBySpace
overload <|>  with catByLine
overload </>  with catBySoftline 
overload <|+> with catByBreak
overload </+> with catBySoftbreak


(* List combinators *)

fun {} catAllBy           (list doc, (doc, doc) -> doc): doc

fun {} catAllBySpace      (list doc): doc 
fun {} catAllByLine       (list doc): doc 
fun {} catAllBySoftline   (list doc): doc 
fun {} catAllByLineGroup  (list doc): doc

fun {} catAllDirectly     (list doc): doc 
fun {} catAllByBreak      (list doc): doc 
fun {} catAllBySoftbreak  (list doc): doc 
fun {} catAllByBreakGroup (list doc): doc 

fun {} punctuate (list doc, doc): list doc (* concat docs sep by a user given doc *)


(* Alignment *)

(* 
	`align` set the nesting level to the current column.

	>> primitive "hi" <+> (align (primitive "nice" <|> primitive "world"))
	-- hi nice
	--    world


	`hang` set the nesting level to the current column plus n.

	>> test = "the" "hang" "combinator" "indents" "these" "words" "!"
	>> hang (test, 4) // with page width 20
	-- the hang combinator 
	--     indents these
	--     words !


	`indent` indends n from current column. e.g.

	>> test = "the" "hang" "combinator" "indents" "these" "words" "!"
	>> indent (test, 4)
	--     the indent
	--     combinator
	--     indents these
	--     words !
*)

fun align  (doc): doc      
fun hang   (doc, int): doc 
fun indent (doc, int): doc 


(* Characters *)

fun lparen    (): doc
fun rparen    (): doc
fun langle    (): doc
fun rangle    (): doc
fun lbrace    (): doc
fun rbrace    (): doc
fun lbracket  (): doc
fun rbracket  (): doc
fun squote    (): doc
fun dquote    (): doc
fun semi      (): doc
fun colon     (): doc
fun comma     (): doc
fun space     (): doc
fun dot       (): doc
fun backslash (): doc
fun equals    (): doc
fun at        (): doc
fun sharp     (): doc


(* Bracketing combinators *)

fun {} enclose	(doc, doc, doc): doc
fun {} squotes	(doc): doc
fun {} dquotes	(doc): doc
fun {} parens	(doc): doc
fun {} angles	(doc): doc
fun {} braces	(doc): doc
fun {} brackets	(doc): doc


(* List and bracketing *)

fun {} encloseSep    (list doc, doc, doc, doc): doc
fun {} commaBrackets (list doc): doc   // renamed from `list`
fun {} commaParens   (list doc): doc   // renamed from `tupled`
fun {} semiBraces    (list doc): doc 


(* Fillers *)

(* 
	`fill` pad doc to at least n width, or do nothing 

	 => let empty  :: Doc
	 =>	    nest   :: Int -> Doc -> Doc
	        linebreak
	               :: Doc

	`fillBreak` pad doc to at least n width, or put the rest to the next line by insert a linebreak 

		let empty  :: Doc
		    nest   :: Int -> Doc -> Doc
	 =>     linebreak
	 =>            :: Doc
*)

fun {} fill      (doc, int): doc 
fun {} fillBreak (doc, int): doc 


(* Renderers *)

abstype simpledoc

fun {} renderPretty (doc, double, int): simpledoc 
fun {} renderCompact (doc): simpledoc
fun {} displayStr (simpledoc): string 
fun {} displayStdout (simpledoc): void