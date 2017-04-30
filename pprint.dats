#define ATS_DYNLOADFLAG 0
#include "share/atspre_staload.hats"
#include "ats-utils/atsutils.hats"
staload "ats-utils/string.sats"
staload "ats-utils/list.sats"
staload "ats-utils/maybe.sats"

staload "./pprint.sats"

datatype Doc = 
| Empty
| Char    of char                 (* char is not '\n' *)
| Text    of (int, string)        (* does not contain '\n' *)
| Line    of bool                 (* true means empty or line, false means space or line *)
| Cat     of (Doc, Doc)
| Nest    of (int, Doc)			  (* set nesting level of the doc *)
| Union   of (Doc, Doc)           (* two alternative layouts, where first is flattned, second is not *)
| Column  of (int -<cloref1> Doc) (* int is the current column *)
| Nesting of (int -<cloref1> Doc) (* int is the current nesting level *)

assume doc = Doc

#define :: ListCons
#define nil ListNil


(* Operators *)

infixr (+ +1) <:>  // cat x and y, <>
infixr (+ +1) <+>  // cat x and space and y, <+>
infixr (+) <|>     // cat x and line and y, <$>
infixr (+) </>     // cat x and softline and y, </>
infixr (+) <|+>    // cat x and linebreak and y, <$$>
infixr (+) </+>    // cat x and softbreak and y, <//>

implement cat            (x, y) = Cat (x, y)
implement catBySpace     (x, y) = x <:> space () <:> y
implement catByLine      (x, y) = x <:> line () <:> y
implement catBySoftline  (x, y) = x <:> softline () <:> y
implement catByBreak     (x, y) = x <:> linebreak () <:> y
implement catBySoftbreak (x, y) = x <:> softbreak () <:> y


(* List combinators *)

implement {} catAllBy (ds, by) = foldr (ds, emp(), lam (d, ds) => by (d, ds))

implement {} catAllByLineGroup  (ds) = group (catAllByLine ds)
implement {} catAllBySpace      (ds) = catAllBy (ds, catBySpace)
implement {} catAllByLine       (ds) = catAllBy (ds, catByLine)
implement {} catAllBySoftline   (ds) = catAllBy (ds, catBySoftline)

implement {} catAllByBreakGroup (ds) = group (catAllByBreak ds)
implement {} catAllDirectly     (ds) = catAllBy (ds, cat)
implement {} catAllByBreak      (ds) = catAllBy (ds, catByBreak)
implement {} catAllBySoftbreak  (ds) = catAllBy (ds, catBySoftbreak)

implement {} punctuate (ds, p) = 
	case+ ds of 
	| nil () => nil ()
	| x :: nil () => ds 
	| x :: xs => (x <:> p) :: punctuate (xs, p)


(* Local functions *)

extern fun text (string): doc (* a string (no '\n') doc *)
implement text (s) = if s = "" then emp () else Text (len s, s)

extern fun spaces      (int): string 
extern fun indentation (int): string 
implement spaces      (n) = if n <= 0 then "" else string_prepend (spaces (n-1), ' ')
implement indentation (n) = spaces (n)



(* Primitives *)

implement primitive<char>   (c) = if c = '\n' then line () else Char c
implement primitive<bool>   (b) = if b then text "true" else text "false"
implement primitive<int>    (i) = text (string_from_int i)
implement primitive<double> (d) = text (string_from_double d)
implement primitive<string> (s) = let
	val l = len s
in 
	if s = "" then emp ()
	else if head s = '\n' then line () <:> primitive<string> (tail s)
	else case+ string_find (s, "\n") of 
		| Nothing () => text s
		| Just n     => 
			let val fst = string_range (s, 0, n)
				val snd = string_range (s, n, l) // '\n' is included in snd
			in text fst <:> primitive<string> snd end
end


(* Basic combinators *)

implement emp       ()     = Empty ()
implement line      ()     = Line false
implement linebreak ()     = Line true
implement softline  ()     = group (line ())
implement softbreak ()     = group (linebreak ())
implement nest      (d, i) = Nest (i, d)

implement group (d) = let 
	fun flatten (d:doc): doc = 
		case+ d of 
		| Cat (x, y)   => Cat (flatten x, flatten y)
		| Nest (i, x)  => Nest (i, flatten x)
		| Line (b)     => if b then Empty else Text (1, " ")
		| Union (x, y) => flatten x
		| Column (f)   => Column (lam x => flatten (f x))
		| Nesting (f)  => Nesting (lam x => flatten (f x))
		| _            => d
in 
	Union (flatten d, d) 
end


(* Alignment *)

implement align  (d)    = Column (lam col => Nesting (lam indent => nest (d, col-indent)))
implement hang   (d, i) = align (nest (d, i))
implement indent (d, i) = hang (text (spaces i) <:> d, i)


(* Characters *)

implement lparen    () = Char '\('
implement rparen    () = Char ')'
implement langle    () = Char '<'
implement rangle    () = Char '>'
implement lbrace    () = Char '\{'
implement rbrace    () = Char '}'
implement lbracket  () = Char '\['
implement rbracket  () = Char ']'
implement squote    () = Char '\''
implement dquote    () = Char '"'
implement semi      () = Char ';'
implement colon     () = Char ':'
implement comma     () = Char ','
implement space     () = Char ' '
implement dot       () = Char '.'
implement backslash () = Char '\\'
implement equals    () = Char '='
implement at        () = Char '@'
implement sharp     () = Char '#'


(* Bracketing combinators *)

implement {} enclose  (d, left, right) = left <:> d <:> right
implement {} squotes  (d) = enclose (d, squote(), squote())
implement {} dquotes  (d) = enclose (d, dquote(), dquote())
implement {} parens   (d) = enclose (d, lparen(), rparen())
implement {} angles   (d) = enclose (d, langle(), rangle())
implement {} braces   (d) = enclose (d, lbrace(), rbrace())
implement {} brackets (d) = enclose (d, lbracket(), rbracket ())


(* List and bracketing *)

implement {} encloseSep (ds, left, right, sep) = 
	case+ ds of 
	| nil () => left <:> right
	| d :: nil () => left <:> d <:> right
	| d :: ds => align (catAllByBreakGroup ((left <:> d) :: map (ds, lam d => sep <:> d)) <:> right)

implement {} commaBrackets (xs) = encloseSep (xs, lbracket(), rbracket(), comma())
implement {} commaParens (xs)   = encloseSep (xs, lparen(), rparen(), comma())
implement {} semiBraces (xs)    = encloseSep (xs, lbrace(), rbrace(), semi())


(* Fillers *)

local 

fun width (d: doc, f: int -<cloref1> doc) = Column (lam k1 => d <:> Column (lam k2 => f (k2 - k1)))

in 

implement {} fill      (d, n) = width (d, lam w => if w >= n then emp() else text (spaces (n - w)))
implement {} fillBreak (d, n) = width (d, lam w => if w > n then nest (linebreak(), n) else text (spaces (n - w)))

end


(* Renderers *)

datatype SimpleDoc = 
| SEmpty
| SChar of (char, SimpleDoc)
| SText of (int, string, SimpleDoc)
| SLine of (int, SimpleDoc)

assume simpledoc = SimpleDoc

datatype Docs = 
| DocNil
| DocCons of (int, Doc, Docs) // int is current nesting level


implement {} renderPretty (d, ribbonfrac, width) = let 
	
	fun min (x:int, y:int): int = if x <= y then x else y
	fun max (x:int, y:int): int = if x >= y then x else y

	val ribbonwidth = max (0, min (width, g0f2i (width * ribbonfrac)))

	fun best (ds:Docs, indent:int, col:int): simpledoc = 
		case+ ds of 
		| DocNil ()  => SEmpty ()
		| DocCons (i, d, ds) => 
			case+ d of 
			| Empty ()      => best (ds, indent, col)
			| Char c        => SChar (c, best (ds, indent, col+1))
			| Text (len, s) => SText (len, s, best (ds, indent, col+len))
			| Line _        => SLine (i, best (ds, i, i))
			| Cat (x, y)    => best (DocCons (i, x, DocCons (i, y, ds)), indent, col)
			| Nest (j, x)   => best (DocCons (i+j, x, ds), indent, col)
			| Union (x, y)  => nicest (best(DocCons(i,x,ds),indent,col), best(DocCons(i,y,ds),indent,col), indent, col)
			| Column f      => best (DocCons (i, f col, ds), indent, col)
			| Nesting f     => best (DocCons (i, f i, ds), indent, col)

	and nicest (x:simpledoc, y:simpledoc, indent:int, col:int): simpledoc = 
		if fits (x, min (width-col, ribbonwidth+indent-col)) then x else y

	and fits (ds:simpledoc, width:int): bool = 
		if width < 0 then false
		else case+ ds of 
			 | SEmpty ()          => true
			 | SChar (_, ds)      => fits (ds, width-1)
			 | SText (len, _, ds) => fits (ds, width-len)
			 | SLine _            => true
in 
	best (DocCons (0, d, DocNil()), 0, 0)
end

//implement {} renderCompact (doc): simpledoc

implement {} displayStr (d) = let 

	fun display (d:simpledoc): list string = 
		case+ d of 
		| SEmpty () => nil ()
		| SChar (c, x) => string_from_char c :: display x
		| SText (l, s, x) => s :: display x 
		| SLine (i, x) => "\n" :: indentation i :: display x

in 
	string_join (display d, "")
end

implement {} displayStdout (d) = println! (displayStr d)


//implement main0 () = () where {
//	val test = text ("list") <+> commaBrackets (map (10::20::300::2000::13::130::nil(), lam x => primitive<int> x))
//	val _ = println! (displayStr (renderPretty (test, 0.6, 40)))
//}


