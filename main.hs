import System.Environment (getArgs)

import Ast
import Interpreter (runProgram)
import Compiler (compile)

main :: IO ()
main = do
  args <- getArgs
  case (args) of
    ["c"] -> putStr . compile $ prog
    ["i"] -> runProgram prog
    _     -> putStrLn "Usage: `./main c` or `./main i`"
    
prog :: Program
prog = [Assign 'a' (Add (Val 2) (Val 3)),
        Read 'b',
        Print (Add (Var 'a') (Var 'b'))]