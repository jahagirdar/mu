{-# OPTIONS_GHC -fglasgow-exts -funbox-strict-fields #-}

module Pugs.Parser.Types (
    RuleParser, RuleState(..),
    DynParsers(..), ParensOption(..),
    RuleOperator, RuleOperatorTable,
    getRuleEnv, modifyRuleEnv, putRuleEnv,
    clearDynParsers,
) where
import Pugs.AST
import Pugs.Rule
import Pugs.Rule.Expr
import Pugs.Internals

{-|
Cache holding dynamically-generated parsers for user-defined operators.  This
means we don't have to rebuild them for each token.

The cache is generated inside 'Pugs.Parser.parseOpWith'.
It is cleared each time we do compile-time evaluation with
'Pugs.Parser.Unsafe.unsafeEvalExp', by calling 'clearDynParsers'.

Stored inside 'RuleState', the state component of 'RuleParser'.
-}
data DynParsers = MkDynParsersEmpty | MkDynParsers
    { dynParseOp       :: !(RuleParser Exp)
    , dynParseTightOp  :: !(RuleParser Exp)
    , dynParseLitOp    :: !(RuleParser Exp)
    }

{-|
State object that gets passed around during the parsing process.
-}
data RuleState = MkRuleState
    { ruleEnv           :: !Env
    , ruleDynParsers    :: !DynParsers -- ^ Cache for dynamically-generated
                                       --     parsers
    }

{-|
A parser that operates on @Char@s, and maintains state in a 'RuleState'.
-}
type RuleParser a = GenParser Char RuleState a

data ParensOption = ParensMandatory | ParensOptional
    deriving (Show, Eq)

instance MonadState RuleState (GenParser Char RuleState) where
    get = getState
    put = setState

type RuleOperator a = Operator Char RuleState a
type RuleOperatorTable a = OperatorTable Char RuleState a

{-|
Retrieve the 'Pugs.AST.Internals.Env' from the current state of the parser.
-}
getRuleEnv :: RuleParser Env
getRuleEnv = gets ruleEnv

{-|
Update the 'Pugs.AST.Internals.Env' in the parser's state by applying a transformation function.
-}
modifyRuleEnv :: (MonadState RuleState m) => (Env -> Env) -> m ()
modifyRuleEnv f = modify $ \state -> state{ ruleEnv = f (ruleEnv state) }

{-|
Replace the 'Pugs.AST.Internals.Env' in the parser's state with a new one.
-}
putRuleEnv :: Env -> RuleParser ()
putRuleEnv = modifyRuleEnv . const

{-|
Clear the parser's cache of dynamically-generated parsers for user-defined
operators.

These will be re-generated by 'Pugs.Parser.parseOpWith' when needed.
-}
clearDynParsers :: RuleParser ()
clearDynParsers = modify $ \state -> state{ ruleDynParsers = MkDynParsersEmpty }
