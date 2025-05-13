-- import LatestMath
import MathlibDepsExtractor.DepExtractor
import Lean
import Lean.Elab.BuiltinCommand
import Lean.Meta.Basic
open Lean Elab Term Meta

def exclude_prefix := #["Lean", "Std", "IO","_", "Aesop"]

#check Array.all

def getAllNamespacesWithoutPrefix (prefixes : Array String): TermElabM (List Name) := do
  let env ← getEnv

  let namespaces := env.getNamespaceSet.fold (fun res name =>
    if prefixes.all (fun pref => ! name.toString.startsWith pref) then name :: res else res) []
  return namespaces
  -- let sth := (env.getNamespaceSet.fold (fun res name => res) [])
  -- let consts := env.constants.fold (fun res name _ => if name.getRoot.toString == "traft" then name :: res else res) []
  -- IO.println (consts.take 20)

-- #eval getAllNamespacesWithoutPrefix exclude_prefix

-- #check rfl
-- def main : IO Unit := do
--   let mathlib_file ← IO.FS.readFile "Mathlib"
--   let refs := (mathlib_file.splitOn "\n").filterMap (fun line => line.dropPrefix? "import ")
--   -- refs 均为所需的命名空间
--   IO.FS.createDir "extracted"
--   IO.println refs
--   for ref in refs do
--     serializeAndWriteToFileInDir (.Namespace ref.toString) 1 "extracted"
--   IO.println "Hello Mathlib4"
--   return
-- #check Unit → α
-- #eval show IO Unit from do
--   IO.println "Hello eval"
--   (← IO.getStdout).flush
--   IO.sleep 1000
--   IO.println "Bye eval"

#eval show IO Unit from do
  let target := System.mkFilePath ["extracted", "Witt".append ".json"]
  IO.println (← target.pathExists)

def IOTermElab.run (x : IO (TermElabM α)) : TermElabM α := do
  let io : TermElabM α ← x
  io

def IOTermElab.build (x : TermElabM α) : IO (TermElabM α) := do
  pure x

#check List.range

def ext_main : Lean.Elab.Term.TermElabM PUnit := do
  -- let mathlib_file ← IO.FS.readFile "Mathlib"
  -- let refs := (mathlib_file.splitOn "\n").filterMap (fun line => line.dropPrefix? "import ")
  let refs ← getAllNamespacesWithoutPrefix exclude_prefix
  let refs := List.mergeSort refs (fun a b => a.toString < b.toString)
  -- refs 均为所需的命名空间
  -- if IO.FS.dir IO.FS.createDir "extracted"
  let console := System.mkFilePath ["extracted", "log.stdout"]
  let logfile ← IO.FS.readFile console
  let latest_name := (((logfile.trim.splitOn "\n").getLastD "").splitOn " ").getD 1 ""
  let refs := refs.filter (fun ref => ref.toString > latest_name)

  let total := refs.length
  let enumerated := refs.zipIdx 1

  IOTermElab.run (IO.FS.withFile (α := TermElabM PUnit) console IO.FS.Mode.append fun handle => do
    let _ ← IO.setStdout (IO.FS.Stream.ofHandle handle)
    IO.println s!"starting-from {latest_name}"
    (← IO.getStdout).flush
    IOTermElab.build (enumerated.forM (m := TermElabM) fun (ref, i) ↦ do
      let target := System.mkFilePath ["extracted", ref.toString.append ".json"]
      let nonempty ← if ! (← target.pathExists) then
        serializeAndWriteToFileInDir (.Namespace ref.toString) 1 "extracted"
      else
        pure false
      let suffix ← if nonempty then
        if (← target.pathExists) then
          pure "exists-skipped"
        else
          pure "empty"
      else
        pure "empty-skipped"
      IO.println s!"{i}/{total} {ref.toString} {suffix}"
      (← IO.getStdout).flush
    ))

  IO.println "Bye Mathlib4"

-- #eval ext_main
