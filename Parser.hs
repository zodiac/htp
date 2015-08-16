-- TODO: replace all uses of head and tail with pattern matching/total functions
module Parser where
import Text.Parsec hiding (runParser)
import Data.Char          (isDigit, isAlpha)
import Control.Monad.Identity

import Types

type Parser a = ParsecT [Char] () Identity a

parseProgram :: String -> Program
parseProgram = map (resolveError . parseCommand) . lines

runParser :: Parser a -> String -> Either ParseError a
runParser parser = parse parser "(source)"

parseCommand = runParser commandParser
parseExpr = runParser exprParser

resolveError = either (error . show) id

commandParser :: Parser Command
commandParser = do
  command <- many1 letter
  spaces
  expr <- many1 anyChar
  let split = words expr

  return $ case command of
    "print"  ->  Print . resolveError $ parseExpr expr
    "assign" ->
      let ([ident] : value1) = split
          value = resolveError . parseExpr . unwords $ value1
      in Assign ident value

    "read"   -> let [ident] = expr in Read ident
    _        -> error "Invalid command"

constChar :: Char -> a -> Parser a
constChar c f = char c >> return f

arithParser :: Parser Arith
arithParser =    constChar '+' Add
             <|> constChar '-' Sub
             <|> constChar '*' Mul
             <|> constChar '/' Div

valueParser :: Parser Value
valueParser = many1 digit >>= return . read

varParser :: Parser Variable
varParser = anyChar --oneOf ['a'..'z']

parens :: Parser a -> Parser a
parens parser = do
  char '('
  p' <- parser
  char ')'
  return p'

exprParser :: Parser Expr
exprParser = opP <|> valueP <|> varP
  where
    valueP = valueParser >>= return . Val
    varP   = varParser   >>= return . Var
    opP    = do
      e1 <- valueP <|> varP <|> parens opP
      spaces
      op <- arithParser
      spaces
      e2 <- valueP <|> varP <|> parens opP
      return (Op op e1 e2)

{-

exprParser1 :: Parser Expr
exprParser1 = do
  spaces

  itemRaw <- manyTill (digit <|> oneOf ['a'..'z'])
             ((space >> return ()) <|> eof)

  spaces

  rest <- many anyChar
  let item = if all isDigit itemRaw
             then Val $ read itemRaw
             else if (isAlpha . head) itemRaw
             then Var $ head itemRaw
             else error "invalid expression"

  return $ case rest of
    []       -> item
    ('+':xs) -> Add item (parseRest xs)
    ('-':xs) -> Sub item (parseRest xs)
    ('*':xs) -> Mul item (parseRest xs)
    ('/':xs) -> Div item (parseRest xs)
    other    -> error . show $ other
  where
    parseRest :: String -> Expr
    parseRest rest = case runParser exprParser1 rest of
      Right expr -> expr
      Left  err  -> (error . show) err
-}
