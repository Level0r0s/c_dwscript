{**********************************************************************}
{                                                                      }
{    "The contents of this file are subject to the Mozilla Public      }
{    License Version 1.1 (the "License"); you may not use this         }
{    file except in compliance with the License. You may obtain        }
{    a copy of the License at http://www.mozilla.org/MPL/              }
{                                                                      }
{    Software distributed under the License is distributed on an       }
{    "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express       }
{    or implied. See the License for the specific language             }
{    governing rights and limitations under the License.               }
{                                                                      }
{    The Initial Developer of the Original Code is Matthias            }
{    Ackermann. For other initial contributors, see contributors.txt   }
{    Subsequent portions Copyright Creative IT.                        }
{                                                                      }
{    Current maintainer: Eric Grange                                   }
{                                                                      }
{**********************************************************************}
unit dwsMethodExprs;

{$I dws.inc}

interface

uses
   Variants,
   dwsErrors, dwsStrings, dwsUtils,
   dwsSymbols, dwsDataContext, dwsStack, dwsFunctions,
   dwsExprs, dwsExprList, dwsMagicExprs;

type

   TObjectClassNameMethod = class(TInternalMethod)
      procedure Execute(info : TProgramInfo; var ExternalObject: TObject); override;
   end;

   TObjectClassTypeMethod = class(TInternalMethod)
      procedure Execute(info : TProgramInfo; var ExternalObject: TObject); override;
   end;

   TObjectClassParentMethod = class(TInternalMethod)
      procedure Execute(info : TProgramInfo; var ExternalObject: TObject); override;
   end;

   TObjectDestroyMethod = class(TInternalMethod)
      procedure Execute(info : TProgramInfo; var ExternalObject: TObject); override;
   end;

   TObjectFreeMethod = class(TInternalMethod)
      procedure Execute(info : TProgramInfo; var ExternalObject: TObject); override;
   end;

   // Call of a method
   TMethodExpr = class abstract (TFuncExpr)
      private
         FBaseExpr : TTypedExpr;
         FSelfAddr : Integer;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function PreCall(exec : TdwsExecution) : TFuncSymbol; virtual;
         procedure PostCall(exec : TdwsExecution; var Result : Variant); virtual;

      public
         constructor Create(Prog: TdwsProgram; const scriptPos : TScriptPos; Func: TMethodSymbol;
                            BaseExpr: TTypedExpr);
         destructor Destroy; override;

         function Eval(exec : TdwsExecution) : Variant; override;

         function MethSym : TMethodSymbol; inline;

         function ChangeFuncSymbol(aProg: TdwsProgram; newFuncSym : TFuncSymbol) : TFuncExprBase; override;

         property BaseExpr : TTypedExpr read FBaseExpr;
   end;

   // Call of a record method
   TRecordMethodExpr = class (TFuncExpr)
   end;

   // Call of a helper method
   THelperMethodExpr = class (TFuncExpr)
      public
         constructor Create(prog : TdwsProgram; const scriptPos : TScriptPos; func : TFuncSymbol);
   end;

   // Call of static methods (not virtual)
   TMethodStaticExpr = class(TMethodExpr)
      protected
         function PreCall(exec : TdwsExecution) : TFuncSymbol; override;

      public
         function Eval(exec : TdwsExecution) : Variant; override;
   end;

   // Call of an interface methods
   TMethodInterfaceExpr = class(TMethodStaticExpr)
      protected
         function PreCall(exec : TdwsExecution) : TFuncSymbol; override;
   end;

   // Call of an interface anonymous methods
   TMethodInterfaceAnonymousExpr = class(TMethodStaticExpr)
      protected
         function PreCall(exec : TdwsExecution) : TFuncSymbol; override;
   end;

   // Call to a virtual method
   TMethodVirtualExpr = class(TMethodStaticExpr)
      protected
         function FindVirtualMethod(classSym : TClassSymbol): TMethodSymbol; inline;
         function PreCall(exec : TdwsExecution) : TFuncSymbol; override;

      public
   end;

   // Class methods (non virtual)
   TClassMethodStaticExpr = class(TMethodStaticExpr)
      protected
         function PreCall(exec : TdwsExecution) : TFuncSymbol; override;
   end;

   // Call to a virtual class method
   TClassMethodVirtualExpr = class(TClassMethodStaticExpr)
      protected
         function FindVirtualMethod(exec : TdwsExecution) : TMethodSymbol;
         function PreCall(exec : TdwsExecution) : TFuncSymbol; override;
   end;

   // Call to a static constructor
   TConstructorStaticExpr = class(TMethodStaticExpr)
      protected
         procedure DoCreate(exec : TdwsExecution); inline;
         function PreCall(exec : TdwsExecution) : TFuncSymbol; override;
         procedure PostCall(exec : TdwsExecution; var Result : Variant); override;

      public
         constructor Create(Prog: TdwsProgram; const aScriptPos: TScriptPos; Func: TMethodSymbol;
                            Base: TTypedExpr);
   end;

   // Call to a virtual constructor
   TConstructorVirtualExpr = class(TMethodVirtualExpr)
      private
         FExternalObject: TObject;

      protected
         procedure PostCall(exec : TdwsExecution; var Result : Variant); override;
         function PreCall(exec : TdwsExecution) : TFuncSymbol; override;

      public
         constructor Create(Prog: TdwsProgram; const aScriptPos: TScriptPos; Func: TMethodSymbol;
                            Base: TTypedExpr);
         property ExternalObject: TObject read FExternalObject write FExternalObject;
   end;

   // call to default TObject.Create (which is empty)
   TConstructorStaticDefaultExpr = class(TConstructorStaticExpr)
      public
         function Eval(exec : TdwsExecution) : Variant; override;
   end;

   TConstructorStaticObjExpr = class(TMethodStaticExpr)
      protected
         procedure PostCall(exec : TdwsExecution; var Result : Variant); override;
      public
         constructor Create(Prog: TdwsProgram; const aScriptPos: TScriptPos; Func: TMethodSymbol;
                            BaseExpr: TTypedExpr);
   end;

   TConstructorVirtualObjExpr = class(TMethodVirtualExpr)
      protected
         procedure PostCall(exec : TdwsExecution; var Result : Variant); override;
      public
         constructor Create(Prog: TdwsProgram; const aScriptPos: TScriptPos; Func: TMethodSymbol;
                            Base: TTypedExpr);
   end;

   TDestructorStaticExpr = class(TMethodStaticExpr)
      protected
         procedure PostCall(exec : TdwsExecution; var Result : Variant); override;
   end;

   TDestructorVirtualExpr = class(TMethodVirtualExpr)
      protected
         procedure PostCall(exec : TdwsExecution; var Result : Variant); override;
   end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

uses dwsCompilerUtils;

// ------------------
// ------------------ TObjectClassNameMethod ------------------
// ------------------

// Execute
//
procedure TObjectClassNameMethod.Execute(info : TProgramInfo; var ExternalObject: TObject);
var
   classSym : TClassSymbol;
begin
   classSym:=info.ValueAsClassSymbol[SYS_SELF];
   if classSym=nil then
      raise EScriptError.CreatePosFmt(info.Execution.CallStackLastExpr.ScriptPos, RTE_ClassTypeIsNil, []);
   Info.ResultAsString:=classSym.Name;
end;

// ------------------
// ------------------ TObjectClassTypeMethod ------------------
// ------------------

// Execute
//
procedure TObjectClassTypeMethod.Execute(info : TProgramInfo; var ExternalObject: TObject);
begin
   Info.ResultAsInteger:=Int64(info.ValueAsClassSymbol[SYS_SELF]);
end;

// ------------------
// ------------------ TObjectClassParentMethod ------------------
// ------------------

// Execute
//
procedure TObjectClassParentMethod.Execute(info : TProgramInfo; var ExternalObject: TObject);
var
   p : TClassSymbol;
begin
   p:=info.ValueAsClassSymbol[SYS_SELF].Parent;
   if p=Info.Execution.Prog.TypObject then
      p:=nil;
   Info.ResultAsInteger:=Int64(p);
end;

// ------------------
// ------------------ TObjectDestroyMethod ------------------
// ------------------

// Execute
//
procedure TObjectDestroyMethod.Execute(info : TProgramInfo; var ExternalObject: TObject);
var
   scriptObj : PIScriptObj;
begin
   scriptObj:=info.Execution.SelfScriptObject;
   scriptObj.Destroyed:=True;
end;

// ------------------
// ------------------ TObjectFreeMethod ------------------
// ------------------

// Execute
//
procedure TObjectFreeMethod.Execute(info : TProgramInfo; var ExternalObject: TObject);
var
   scriptObj : PIScriptObj;
begin
   scriptObj:=info.Execution.SelfScriptObject;

   if (scriptObj^<>nil) then
      info.Method['Destroy'].Call;
end;

// ------------------
// ------------------ TMethodExpr ------------------
// ------------------

// Create
//
constructor TMethodExpr.Create(Prog: TdwsProgram; const scriptPos: TScriptPos;
  Func: TMethodSymbol; BaseExpr: TTypedExpr);
begin
   inherited Create(Prog, scriptPos, Func);
   FBaseExpr:=BaseExpr;
   FSelfAddr:=Func.SelfSym.StackAddr;
end;

// Destroy
//
destructor TMethodExpr.Destroy;
begin
   FBaseExpr.Free;
   inherited;
end;

// Eval
//
function TMethodExpr.Eval(exec : TdwsExecution) : Variant;
var
   func : TFuncSymbol;
begin
   // Allocate memory for parameters on the stack
   try
      exec.Stack.Push(ParamSize);
      try
         func:=PreCall(exec);

         DoEvalCall(exec, func);

         PostCall(exec, Result);
      finally
         // Remove parameters from stack
         exec.Stack.Pop(ParamSize);
      end;
   except
      exec.SetScriptError(Self);
      raise;
   end;
end;

// MethSym
//
function TMethodExpr.MethSym : TMethodSymbol;
begin
   Result:=TMethodSymbol(FuncSym);
end;

// ChangeFuncSymbol
//
function TMethodExpr.ChangeFuncSymbol(aProg: TdwsProgram; newFuncSym : TFuncSymbol) : TFuncExprBase;
var
   newMeth : TMethodSymbol;
   refKind : TRefKind;
begin
   newMeth:=(newFuncSym as TMethodSymbol);

   if BaseExpr.Typ is TStructuredTypeMetaSymbol then begin
      Assert(newMeth.IsClassMethod or (newMeth.Kind=fkConstructor));
      refKind:=rkClassOfRef;
   end else refKind:=rkObjRef;

   Result:=CreateMethodExpr(aProg, newMeth, Self.FBaseExpr, refKind, ScriptPos);
   Result.Args.Assign(Args);
   Self.FArgs.Clear;
   Self.Free;
end;

// GetSubExpr
//
function TMethodExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FBaseExpr;
   else
      Result:=inherited GetSubExpr(i-1);
   end;
end;

// GetSubExprCount
//
function TMethodExpr.GetSubExprCount : Integer;
begin
   Result:=FArgs.Count+1;
end;

// PreCall
//
function TMethodExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
begin
   Result:=FuncSym;
end;

// PostCall
//
procedure TMethodExpr.PostCall(exec : TdwsExecution; var Result : Variant);
begin
   if Typ<>nil then
      StaticPostCall(exec, Result);
end;

// ------------------
// ------------------ THelperMethodExpr ------------------
// ------------------

// Create
//
constructor THelperMethodExpr.Create(prog : TdwsProgram; const scriptPos : TScriptPos; func : TFuncSymbol);
begin
   if func.ClassType=TAliasMethodSymbol then
      func:=TAliasMethodSymbol(func).Alias;
   inherited Create(prog, scriptPos, func);

end;

// ------------------
// ------------------ TMethodStaticExpr ------------------
// ------------------

// Eval
//
function TMethodStaticExpr.Eval(exec : TdwsExecution) : Variant;
var
   scriptObj : Pointer;
   oldSelf : PIScriptObj;
begin
   scriptObj:=nil;
   oldSelf:=exec.SelfScriptObject;
   try
      exec.SelfScriptObject:=@scriptObj;
      Result:=inherited Eval(exec);
   finally
      exec.SelfScriptObject:=oldSelf;
      IScriptObj(scriptObj):=nil;
   end;
end;

// PreCall
//
function TMethodStaticExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
var
   p : PIScriptObj;
begin
   p:=exec.SelfScriptObject;
   FBaseExpr.EvalAsScriptObj(exec, p^);
   if (p^<>nil) and p^.Destroyed then
      RaiseObjectAlreadyDestroyed(exec);
   exec.Stack.WriteInterfaceValue(exec.Stack.StackPointer+FSelfAddr, p^);

   Result:=FuncSym;
end;

// ------------------
// ------------------ TMethodInterfaceExpr ------------------
// ------------------

// PreCall
//
function TMethodInterfaceExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
var
   scriptObj : IScriptObj;
   intfObj : TScriptInterface;
begin
   FBaseExpr.EvalAsScriptObj(exec, scriptObj);
   CheckInterface(exec, scriptObj);
   intfObj:=TScriptInterface(scriptObj.GetSelf);
   exec.SelfScriptObject^:=intfObj.Instance;
   exec.Stack.WriteInterfaceValue(exec.Stack.StackPointer+FSelfAddr, intfObj.Instance);
   Result:=intfObj.VMT[TMethodSymbol(FuncSym).VMTIndex];
end;

// ------------------
// ------------------ TMethodInterfaceAnonymousExpr ------------------
// ------------------

// PreCall
//
function TMethodInterfaceAnonymousExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
var
   intf : Variant;
begin
   FBaseExpr.EvalAsVariant(exec, intf);
   exec.Stack.WriteValue(exec.Stack.StackPointer+FSelfAddr, intf);
   Result:=FuncSym;
end;

// ------------------
// ------------------ TMethodVirtualExpr ------------------
// ------------------

// FindVirtualMethod
//
function TMethodVirtualExpr.FindVirtualMethod(ClassSym: TClassSymbol): TMethodSymbol;
begin
   Result:=ClassSym.VMTMethod(TMethodSymbol(FuncSym).VMTIndex);
end;

// PreCall
//
function TMethodVirtualExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
var
   p : PIScriptObj;
begin
   // Find virtual method
   p:=exec.SelfScriptObject;
   FBaseExpr.EvalAsScriptObj(exec, p^);
   CheckScriptObject(exec, p^);
   exec.Stack.WriteInterfaceValue(exec.Stack.StackPointer+FSelfAddr, p^);
   Result:=FindVirtualMethod(p^.ClassSym);
end;

// ------------------
// ------------------ TClassMethodStaticExpr ------------------
// ------------------

// PreCall
//
function TClassMethodStaticExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
var
   buf : Int64;
begin
   if FBaseExpr.Typ is TClassOfSymbol then
      buf:=FBaseExpr.EvalAsInteger(exec)
   else begin
      FBaseExpr.EvalAsScriptObj(exec, exec.SelfScriptObject^);
      CheckScriptObject(exec, exec.SelfScriptObject^);
      buf:=Int64(exec.SelfScriptObject^.ClassSym);
      exec.SelfScriptObject^:=nil;
   end;
   exec.Stack.WriteIntValue(exec.Stack.StackPointer + FSelfAddr, buf);
   Result := FuncSym;
end;

// ------------------
// ------------------ TClassMethodVirtualExpr ------------------
// ------------------

// FindVirtualMethod
//
function TClassMethodVirtualExpr.FindVirtualMethod(exec : TdwsExecution) : TMethodSymbol;
var
   clsInt : Int64;
   classSym : TClassSymbol;
begin
   clsInt:=exec.Stack.ReadIntValue(exec.Stack.StackPointer+FSelfAddr);
   classSym:=TClassSymbol(clsInt);
   if classSym=nil then
      RaiseScriptError(exec, RTE_ClassTypeIsNil);

   Result:=ClassSym.VMTMethod(TMethodSymbol(FuncSym).VMTIndex);
end;

// PreCall
//
function TClassMethodVirtualExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
begin
   inherited PreCall(exec);

   Result:=FindVirtualMethod(exec);
end;

// ------------------
// ------------------ TConstructorStaticExpr ------------------
// ------------------

constructor TConstructorStaticExpr.Create(Prog: TdwsProgram; const aScriptPos: TScriptPos;
   Func: TMethodSymbol; Base: TTypedExpr);
begin
  inherited Create(Prog, aScriptPos, Func, Base);
  if Base.Typ is TClassOfSymbol then
    FTyp := Base.Typ.Typ
  else
    FTyp := Base.Typ;
end;

// DoCreate
//
procedure TConstructorStaticExpr.DoCreate(exec : TdwsExecution);
var
   classSym : TClassSymbol;
begin
   classSym:=TClassSymbol(BaseExpr.EvalAsInteger(exec));
   if classSym=nil then
      RaiseScriptError(exec, RTE_ClassTypeIsNil);

   // Create object
   exec.SelfScriptObject^:=TScriptObjInstance.Create(classSym, exec as TdwsProgramExecution);
   exec.SelfScriptObject^.ExternalObject:=exec.ExternalObject;
end;

// PreCall
//
function TConstructorStaticExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
begin
   DoCreate(exec);

   exec.Stack.WriteInterfaceValue(exec.Stack.StackPointer+FSelfAddr, exec.SelfScriptObject^);

   Result:=FuncSym;
end;

// PostCall
//
procedure TConstructorStaticExpr.PostCall(exec : TdwsExecution; var Result : Variant);
begin
   Assert(FResultAddr=-1);
   Result:=exec.SelfScriptObject^;
end;

// ------------------
// ------------------ TConstructorVirtualExpr ------------------
// ------------------

constructor TConstructorVirtualExpr.Create(Prog: TdwsProgram; const aScriptPos: TScriptPos;
   Func: TMethodSymbol; Base: TTypedExpr);
begin
  inherited Create(Prog, aScriptPos, Func, Base);
  FTyp := Base.Typ.Typ;
end;

// PreCall
//
function TConstructorVirtualExpr.PreCall(exec : TdwsExecution) : TFuncSymbol;
var
  classInt : Int64;
  classSym : TClassSymbol;
begin
  // Get class symbol
  classInt := FBaseExpr.EvalAsInteger(exec);
  classSym := TClassSymbol(classInt);
  Assert(classSym <> nil);

  if classSym.IsAbstract then
    RaiseScriptError(exec, RTE_InstanceOfAbstractClass);

  Result := FindVirtualMethod(classSym);

  // Create object
  exec.SelfScriptObject^ := TScriptObjInstance.Create(classSym, exec as TdwsProgramExecution);
  exec.SelfScriptObject^.ExternalObject := ExternalObject;

  exec.Stack.WriteInterfaceValue(exec.Stack.StackPointer + FSelfAddr, exec.SelfScriptObject^);
end;

// PostCall
//
procedure TConstructorVirtualExpr.PostCall(exec : TdwsExecution; var Result : Variant);
begin
   // Return Self as Result
   Assert(FResultAddr=-1);
   Result:=exec.SelfScriptObject^;
end;

// ------------------
// ------------------ TConstructorStaticDefaultExpr ------------------
// ------------------

// Eval
//
function TConstructorStaticDefaultExpr.Eval(exec : TdwsExecution) : Variant;
var
   scriptObj : Pointer;
   oldSelf : PIScriptObj;
begin
   scriptObj:=nil;
   oldSelf:=exec.SelfScriptObject;
   try
      exec.SelfScriptObject:=@scriptObj;
      DoCreate(exec);
      Result:=exec.SelfScriptObject^;
   finally
      exec.SelfScriptObject:=oldSelf;
      IScriptObj(scriptObj):=nil;
   end;
end;

// ------------------
// ------------------ TConstructorStaticObjExpr ------------------
// ------------------

constructor TConstructorStaticObjExpr.Create(Prog: TdwsProgram;
  const aScriptPos: TScriptPos; Func: TMethodSymbol; BaseExpr: TTypedExpr);
begin
   inherited Create(Prog, aScriptPos, Func, BaseExpr);
   Typ := BaseExpr.Typ;
end;

procedure TConstructorStaticObjExpr.PostCall(exec : TdwsExecution; var Result : Variant);
begin
   Result := exec.SelfScriptObject^;
end;

// ------------------
// ------------------ TConstructorVirtualObjExpr ------------------
// ------------------

constructor TConstructorVirtualObjExpr.Create(Prog: TdwsProgram;
  const aScriptPos: TScriptPos; Func: TMethodSymbol; Base: TTypedExpr);
begin
   inherited Create(Prog, aScriptPos, Func, Base);
   Typ := Base.Typ;
end;

procedure TConstructorVirtualObjExpr.PostCall(exec : TdwsExecution; var Result : Variant);
begin
   Result := exec.SelfScriptObject^;
end;

// ------------------
// ------------------ TDestructorStaticExpr ------------------
// ------------------

// PostCall
//
procedure TDestructorStaticExpr.PostCall(exec : TdwsExecution; var Result : Variant);
begin
   exec.SelfScriptObject^.Destroyed:=True;
end;

// ------------------
// ------------------ TDestructorVirtualExpr ------------------
// ------------------

// PostCall
//
procedure TDestructorVirtualExpr.PostCall(exec : TdwsExecution; var Result : Variant);
begin
   exec.SelfScriptObject^.Destroyed:=True;
end;

end.
