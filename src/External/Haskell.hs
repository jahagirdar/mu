{-# OPTIONS_GHC -fglasgow-exts -fth -cpp #-}

module External.Haskell where
import AST

#undef PUGS_HAVE_TH
#include "pugs_config.h"
#ifndef PUGS_HAVE_TH
externalizeHaskell :: String -> String -> IO String
externalizeHaskell  = error "Template Haskell support not compiled in"
loadHaskell :: FilePath -> IO [(String, [Val] -> Eval Val)]
loadHaskell         = error "Template Haskell support not compiled in"
#else

import Internals
import Language.Haskell.TH as TH
import Language.Haskell.Parser
import Language.Haskell.Syntax
import External.Haskell.PathLoader

loadHaskell :: FilePath -> IO [(String, [Val] -> Eval Val)]
loadHaskell file = do
    loadModule "/usr/local/lib/ghc-6.4/HSbase.o" MT_Package
    loadModule "/usr/local/lib/ghc-6.4/HShaskell98.o" MT_Package
    loadModule "/usr/local/lib/ghc-6.4/HSmtl.o" MT_Package
    mod     <- loadModule file MT_Module
    func    <- loadFunction mod "extern__"
    (`mapM` func) $ \name -> do
        func <- loadFunction mod $ "extern__" ++ name
        return (name, func)

externalizeHaskell :: String -> String -> IO String
externalizeHaskell mod code = do
    let names = map snd exports
    symTable <- runQ [d| extern__ = names |]
    symDecls <- mapM wrap names
    return $ unlines $
        [ "module " ++ mod ++ " where"
        , "import Internals"
        , "import GHC.Base"
        , "import AST"
        , ""
        , code
        , ""
        , "-- below are automatically generated by Pugs --"
        , TH.pprint symTable
        , TH.pprint symDecls
        ] 
    where
    exports :: [(HsQualType, String)]
    exports = concat [ [ (typ, name) | HsIdent name <- names ]
                     | HsTypeSig _ names typ <- parsed
                     ]
    parsed = case parseModule code of
        ParseOk (HsModule _ _ _ _ decls) -> decls
        ParseFailed _ err -> error err

wrap :: String -> IO Dec
wrap fun = do
    [quoted] <- runQ [d|
            name = \[v] -> do
                s <- fromVal v
                return (castV ($(dyn fun) s))
        |]
    return $ munge quoted ("extern__" ++ fun)

munge (ValD _ x y) name = ValD (VarP (mkName name)) x y
munge _ _ = error "impossible"

#endif

