#############################################################################
##
#W  cmat.gi               GAP 4 package `cvec'                
##                                                            Max Neunhoeffer
##
#Y  Copyright (C)  2005,  Lehrstuhl D fuer Mathematik,  RWTH Aachen,  Germany
##
##  This file contains the higher levels for compact matrices over finite 
##  fields. 
##

#############################################################################
# Creation:
#############################################################################

InstallGlobalFunction( CVEC_CMatMaker, function(l,cl)
    # Makes a new CMat, given a list l with a 0 in the first place
    local greasehint,m,q,qp,ty;
    if Length(l) > 0 then
        m := rec(rows := l, len := Length(l)-1, vecclass := cl,
                 scaclass := cl![CVEC_IDX_GF]);
    else
        m := rec(rows := l, len := 0, vecclass := cl,
                 scaclass := cl![CVEC_IDX_GF]);
    fi;
    m.greasehint := cl![CVEC_IDX_fieldinfo]![CVEC_IDX_bestgrease];   
         # this is the current bestgrease
    q := cl![CVEC_IDX_fieldinfo]![CVEC_IDX_q];
    qp := q^m.greasehint;
    while m.greasehint > 0 and Length(l) < qp do
        m.greasehint := m.greasehint-1;
        qp := qp/q;
    od;
    ty := NewType(CollectionsFamily(CollectionsFamily(
                        cl![CVEC_IDX_fieldinfo]![CVEC_IDX_scafam])),
                  IsCMatRep and IsMutable);
    return Objectify(ty,m);
end );

InstallMethod( CMat, "for a list of cvecs and a cvec", [IsList, IsCVecRep],
  function(l,v)
    return CMat(l,DataType(TypeObj(v)),true);
  end);

InstallMethod( CMat, "for a list of cvecs, a cvec, and a boolean value",
  [IsList, IsCVecRep, IsBool],
  function(l,v,checks)
    return CMat(l,DataType(TypeObj(v)),checks);
  end);

InstallMethod( CMat, "for a list of cvecs", [IsList],
  function(l)
    local c;
    if Length(l) = 0 or not(IsBound(l[1])) then
        Error("CMat: Cannot use one-argument version with empty list");
        return fail;
    fi;
    c := DataType(TypeObj(l[1]));
    return CMat(l,c,true);
  end);

InstallMethod( CMat, "for a list of cvecs, and a boolean value", 
  [IsList, IsBool],
  function(l,checks)
    local c;
    if Length(l) = 0 or not(IsBound(l[1])) then
        Error("CMat: Cannot use two-argument version with empty list and bool");
        return fail;
    fi;
    c := DataType(TypeObj(l[1]));
    return CMat(l,c,checks);
  end);

InstallMethod( CMat, "for a list of cvecs and a cvecclass", 
  [IsList, IsCVecClass],
  function(l,c)
    return CMat(l,c,true);
  end);

InstallMethod( CMat, "for a compressed GF2 matrix",
  [IsList and IsGF2MatrixRep],
  function(m)
  local c,i,l,v;
  l := 0*[1..Length(m)+1];
  c := CVEC_NewCVecClass(2,1,Length(m[1]));
  for i in [1..Length(m)] do
      v := ShallowCopy(m[i]);
      PLAIN_GF2VEC(v);
      l[i+1] := CVec(v,c);
  od;
  return CVEC_CMatMaker(l,c);
end);

InstallMethod( CMat, "for a compressed 8bit matrix",
  [IsList and Is8BitMatrixRep],
  function(m)
  local c,i,l,pd,v;
  l := 0*[1..Length(m)+1];
  pd := Factors(Size(DefaultFieldOfMatrix(m)));
  c := CVEC_NewCVecClass(pd[1],Length(pd),Length(m[1]));
  for i in [1..Length(m)] do
      v := ShallowCopy(m[i]);
      PLAIN_VEC8BIT(v);
      l[i+1] := CVec(v,c);
  od;
  return CVEC_CMatMaker(l,c);
end);

InstallMethod( CMat, "for a list of cvecs, a cvec class, and a boolean value", 
  [IsList,IsCVecClass,IsBool],
  function(l,cl,dochecks)
    local v;
    if dochecks then
        for v in [1..Length(l)] do
            if not(IsBound(l[v])) or not(IsCVecRep(l[v])) or 
               not(IsIdenticalObj(DataType(TypeObj(l[v])),cl)) then
                Error("CVEC_CMat: Not all list entries are correct vectors");
                return fail;
            fi;
        od;
    fi;
    Add(l,0,1);
    return CVEC_CMatMaker(l,cl);
  end);

InstallMethod( Matrix, "for a list of cvecs, an integer, and a cmat",
  [IsList, IsInt, IsCMatRep],
  function(l,rl,m)
    local cl,i,li;
    cl := m!.vecclass;
    if rl <> cl![CVEC_IDX_len] then
        cl := CVEC_NewCVecClassSameField(cl,rl);
    fi;
    if Length(l) = 0 then
        li := [0];
        return CVEC_CMatMaker(li,cl);
    fi;
    if IsCVecRep(l[1]) then
        if not(IsIdenticalObj(cl,DataType(TypeObj(l[1])))) then
            Error("Matrix: cvec not in correct class");
            return fail;
        fi;
        li := [0];
        Append(li,l);
        return CVEC_CMatMaker(li,cl);
    elif IsList(l[1]) then
        li := [0];
        for i in [1..Length(l)] do
            Add(li,CVec(l[i],cl));
        od;
        return CVEC_CMatMaker(li,cl);
    else
        Error("Matrix for cmats: flat initializer not yet implemented");
        return;
    fi;
  end );

# Some methods to make special matrices:

InstallGlobalFunction( CVEC_ZeroMat, function(arg)
  local c,d,i,l,p,x,y;
  if Length(arg) = 2 then
      y := arg[1];
      c := arg[2];   # this must be a cvec class
      if not(IsInt(y)) and not(IsCVecClass(c)) then
          Error("Usage: CVEC_ZeroMat( rows, cvecclass)");
          return;
      fi;
  elif Length(arg) = 4 then
      y := arg[1];
      x := arg[2];
      p := arg[3];
      d := arg[4];
      if not(IsInt(y) and y >= 0) or
         not(IsInt(x) and x >= 0) or
         not(IsPosInt(p) and IsPrime(p)) or
         not(IsPosInt(d) and d < CVEC_MAXDEGREE) then
          Error("Usage: CVEC_ZeroMat( rows, cols, p, d )");
          return;
      fi;
      c := CVEC_NewCVecClass(p,d,x);
  else
      Error("Usage: CVEC_ZeroMat( rows, [ cvecclass | cols, p, d ] )");
      return;
  fi;
  l := 0*[1..y+1];
  for i in [1..y] do
      l[i+1] := CVEC_NEW(c,c![CVEC_IDX_type]);
  od;
  return CVEC_CMatMaker(l,c);
end );

InstallMethod( ZeroMatrix, "for two integers and a cmat",
  [ IsInt, IsInt, IsCMatRep ],
  function( y, x, m )
    local c;
    if x = m!.vecclass![CVEC_IDX_len] then
        return CVEC_ZeroMat(y,m!.vecclass);
    else
        c := CVEC_NewCVecClassSameField(m!.vecclass,x);
        return CVEC_ZeroMat(y,c);
    fi;
  end );

InstallGlobalFunction( CVEC_IdentityMat, function(arg)
  local c,d,i,l,p,y;
  if Length(arg) = 1 then
      c := arg[1];   # this must be a cvec class
      if not(IsCVecClass(c)) then
          Error("Usage: CVEC_IdentityMat(cvecclass)");
          return;
      fi;
      y := c![CVEC_IDX_len];
  elif Length(arg) = 3 then
      y := arg[1];
      p := arg[2];
      d := arg[3];
      if not(IsInt(y) and y >= 0) or
         not(IsPosInt(p) and IsPrime(p)) or
         not(IsPosInt(d) and d < CVEC_MAXDEGREE) then
          Error("Usage: CVEC_IdentityMat( rows, p, d )");
          return;
      fi;
      c := CVEC_NewCVecClass(p,d,y);
  else
      Error("Usage: CVEC_IdentityMat( [ cvecclass | rows, p, d ] )");
      return;
  fi;
  l := 0*[1..y+1];
  for i in [1..y] do
      l[i+1] := CVEC_NEW(c,c![CVEC_IDX_type]);
      l[i+1][i] := 1;   # note that this works for all fields!
  od;
  return CVEC_CMatMaker(l,c);
end );

InstallMethod( IdentityMatrix, "for an integer and a cmat",
  [ IsInt, IsCMatRep ],
  function( rows, m)
    local c;
    if rows = m!.vecclass![CVEC_IDX_len] then
        return CVEC_IdentityMat(m!.vecclass);
    else
        c := CVEC_NewCVecClassSameField(m!.vecclass,rows);
        return CVEC_IdentityMat(c);
    fi;
  end );

InstallGlobalFunction( CVEC_RandomMat, function(arg)
  local c,d,i,j,l,li,p,q,x,y;
  if Length(arg) = 2 then
      y := arg[1];
      c := arg[2];   # this must be a cvec class
      if not(IsInt(y)) and not(IsCVecClass(c)) then
          Error("Usage: CVEC_RandomMat( rows, cvecclass)");
          return;
      fi;
      x := c![CVEC_IDX_len];
      d := c![CVEC_IDX_fieldinfo]![CVEC_IDX_d];   # used later on
      q := c![CVEC_IDX_fieldinfo]![CVEC_IDX_q];  
  elif Length(arg) = 4 then
      y := arg[1];
      x := arg[2];
      p := arg[3];
      d := arg[4];
      q := p^d;
      if not(IsInt(y) and y >= 0) or
         not(IsInt(x) and x >= 0) or
         not(IsPosInt(p) and IsPrime(p)) or
         not(IsPosInt(d) and d < CVEC_MAXDEGREE) then
          Error("Usage: CVEC_RandomMat( rows, cols, p, d )");
          return;
      fi;
      c := CVEC_NewCVecClass(p,d,x);
  else
      Print("Usage: CVEC_RandomMat( rows, [ cvecclass | cols, p, d ] )\n");
      return;
  fi;
  l := 0*[1..y+1];
  if c![CVEC_IDX_fieldinfo]![CVEC_IDX_size] <= 1 then    
      # q is an immediate integer
      li := 0*[1..x];
      for i in [1..y] do
          l[i+1] := CVEC_NEW(c,c![CVEC_IDX_type]);
          for j in [1..x] do
              li[j] := Random([0..q-1]);
          od;
          CVEC_INTREP_TO_CVEC(li,l[i+1]);
      od;
  else    # big scalars!
      li := 0*[1..x*d];
      for i in [1..y] do
          l[i+1] := CVEC_NEW(c,c![CVEC_IDX_type]);
          for j in [1..x*d] do
              li[j] := Random([0..p-1]);
          od;
          CVEC_INTREP_TO_CVEC(li,l[i+1]);
      od;
  fi;
  return CVEC_CMatMaker(l,c);
end );

InstallMethod( ChangeBaseDomain, "for a cmat and a finite field",
  [IsCMatRep,IsField and IsFinite],
  function( m, f )
    local cl,i,l;
    cl := CVEC_NewCVecClass(Characteristic(f),DegreeOverPrimeField(f),
                            m!.vecclass![CVEC_IDX_len]);
    l := [0];
    for i in [2..m!.len+1] do
        l[i] := CVec(Unpack(m!.rows[i]),cl);
    od;
    return CVEC_CMatMaker(l,cl);
  end );



#############################################################################
# Viewing, Printing, Displaying of cmats:
#############################################################################

InstallMethod( ViewObj, "for a cmat", [IsCMatRep and IsMatrix],
function(m)
  local c;
  c := m!.vecclass;
  Print("<");
  if not(IsMutable(m)) then Print("immutable "); fi;
  if HasGreaseTab(m) then Print("greased "); fi;
  Print("cmat ",m!.len,"x",c![CVEC_IDX_len]," over GF(",
        c![CVEC_IDX_fieldinfo]![CVEC_IDX_p],",",
        c![CVEC_IDX_fieldinfo]![CVEC_IDX_d],")>");
end);

InstallMethod( PrintObj, "for a cmat", [IsCMatRep and IsMatrix],
function(m)
  local c,i;
  Print("CMat([");
  for i in [1..m!.len] do
      Print(m!.rows[i+1],",");
  od;
  Print("],",m!.vecclass,")");
end);
  
InstallMethod( Display, "for a cmat", 
  [IsCMatRep and IsMatrix and IsFFECollColl],
function(m)
  local i;
  Print("[");
  for i in [1..m!.len] do
      if i <> 1 then Print(" "); fi;
      Display(m!.rows[i+1]);
  od;
  Print("]\n");
end);

InstallGlobalFunction( OverviewMat, function(M)
  local i,j,s,ts,tz,z;
  z := Length(M);
  s := Length(M[1]);
  tz := QuoInt(z+39,40);
  ts := QuoInt(s+39,40);
  for i in [1..QuoInt(z+tz-1,tz)] do
      for j in [1..QuoInt(s+ts-1,ts)] do
          if IsZero(ExtractSubMatrix(M,[1+(i-1)*tz..Minimum(i*tz,z)],
                                       [1+(j-1)*ts..Minimum(j*ts,s)])) then
              Print(".");
          else
              Print("*");
          fi;
      od;
      Print("\n");
  od;
end );

#############################################################################
# Unpacking:
#############################################################################

InstallMethod( Unpack, "for a cmat", [IsCMatRep],
  function(m)
    local mm,q,i;
    mm := [];
    for i in [2..m!.len+1] do
        Add(mm,Unpack(m!.rows[i]));
    od;
    return mm;
  end );

# (Pseudo) random matrices:

InstallMethod( Randomize, "for a cmat", [ IsCMatRep and IsMutable ],
  function( m )
    local i;
    for i in [2..m!.len+1] do
      Randomize(m!.rows[i]);
    od;
  end );

InstallMethod( Randomize, "for a cmat and a random source", 
  [ IsCMatRep and IsMutable, IsRandomSource ],
  function( m, rs )
    local i;
    for i in [2..m!.len+1] do
      Randomize(m!.rows[i],rs);
    od;
  end );

#############################################################################
# PostMakeImmutable to make subobjects immutable:
#############################################################################

InstallMethod( PostMakeImmutable, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    MakeImmutable(m!.rows);
  end);

#############################################################################
# Elementary list operations for our matrices:
#############################################################################

InstallOtherMethod( Add, "for a cmat, and a cvec",
  [IsCMatRep and IsMatrix and IsMutable, IsCVecRep],
  function(m,v)
    if not(IsIdenticalObj(DataType(TypeObj(v)),m!.vecclass)) then
        Error("Add: only correct cvecs allowed in this matrix");
        return fail;
    fi;
    m!.len := m!.len+1;
    m!.rows[m!.len+1] := v;
  end);
InstallOtherMethod( Add, "for a cmat, a cvec, and a position",
  [IsCMatRep and IsMatrix and IsMutable, IsCVecRep, IsPosInt],
  function(m,v,pos)
    if not(IsIdenticalObj(DataType(TypeObj(v)),m!.vecclass)) then
        Error("Add: only correct cvecs allowed in this matrix");
        return fail;
    fi;
    if pos > m!.len+1 then
        Error("Add: position not possible because denseness");
    fi;
    m!.len := m!.len+1;
    Add(m!.rows,v,pos+1);
  end);

InstallOtherMethod( Remove, "for a cmat, and a position",
  [IsCMatRep and IsMatrix and IsMutable, IsPosInt],
  function(m,pos)
    if pos < 1 or pos > m!.len then
        Error("Remove: position not possible");
        return fail;
    fi;
    m!.len := m!.len-1;
    return Remove(m!.rows,pos+1);
  end);

InstallOtherMethod( \[\], "for a cmat, and a position", 
  [IsCMatRep and IsMatrix, IsPosInt],
  function(m,pos)
    if pos < 1 or pos > m!.len then
        Error("\\[\\]: illegal position");
        return fail;
    fi;
    return m!.rows[pos+1];
  end);

InstallOtherMethod( \[\]\:\=, "for a cmat, a position, and a cvec",
  [IsCMatRep and IsMatrix and IsMutable, IsPosInt, IsCVecRep],
  function(m,pos,v)
    if pos < 1 or pos > m!.len+1 then
        Error("\\[\\]\\:\\=: illegal position");
    fi;
    if not(IsIdenticalObj(DataType(TypeObj(v)),m!.vecclass)) then
        Error("\\[\\]\\:\\=: can only assign cvecs to cmat");
    fi;
    if pos = m!.len+1 then
        m!.len := m!.len + 1;
    fi;
    m!.rows[pos+1] := v;
  end);

InstallMethod( ElmMatrix, "for a cmat and two positions",
  [IsCMatRep and IsMatrix, IsPosInt, IsPosInt],
  function( m, row, col )
    return m!.rows[row+1][col];
  end );

InstallMethod( AssMatrix, "for a cmat, two positions, and an ffe",
  [IsCMatRep and IsMatrix, IsPosInt, IsPosInt, IsObject],
  function( m, row, col, el )
    m!.rows[row+1][col] := el;
  end );

InstallOtherMethod( \{\}, "for a cmat, and a list",
  [IsCMatRep and IsMatrix, IsList],
  function(m,li)
    local l;
    l := m!.rows{li+1};
    return CMat(l,m!.vecclass,false);
  end);

InstallOtherMethod( \{\}\:\=, "for a cmat, a homogeneous list, and a cmat",
  [IsCMatRep and IsMatrix and IsMutable, IsList, 
   IsCMatRep and IsMatrix],
  function(m,l,n)
    local i;
    if not(IsIdenticalObj(m!.vecclass,n!.vecclass)) then
        Error("{}:= : cmats not compatible");
        return;
    fi;
    for i in [1..Length(l)] do
        m!.rows[l[i]+1] := n!.rows[i+1];
    od;
  end);

InstallOtherMethod( Length, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m) return m!.len; end);

InstallMethod( DimensionsMat, "for a cmat",
  [IsCMatRep and IsMatrixObj],
  function(m) return [m!.len,m!.vecclass![2]]; end );

InstallMethod( RowLength, "for a cmat",
  [IsCMatRep and IsMatrix and IsMatrixObj],
  function(m) return m!.vecclass![2]; end );

InstallOtherMethod( ShallowCopy, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m) return CVEC_CMatMaker(ShallowCopy(m!.rows),m!.vecclass); end);

InstallOtherMethod( Collected, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    return Collected(m!.rows{[2..m!.len+1]});
  end);

InstallOtherMethod( DuplicateFreeList, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local l;
    l := DuplicateFreeList(m!.rows);
    return CMat(l,m!.vecclass,false);
  end);

InstallOtherMethod( Append, "for two cmats",
  [IsCMatRep and IsMatrix and IsMutable, IsCMatRep and IsMatrix],
  function(m1,m2)
      local i;
      if not(IsIdenticalObj(m1!.vecclass,m2!.vecclass)) then
          Error("Append: Incompatible matrices");
          return fail;
      fi;
      for i in [2..m2!.len+1] do
          Add(m1!.rows,m2!.rows[i]);
      od;
      m1!.len := m1!.len + m2!.len;
  end);

InstallOtherMethod( FilteredOp, "for a cmat and a function",
  [IsCMatRep and IsMatrix, IsFunction],
  function(m,f)
    local l;
    l := Filtered(m!.rows{[2..m!.len+1]},f);
    return CMat(l,m!.vecclass,false);
  end);

InstallOtherMethod( UNB_LIST, "for a cmat and a position",
  [IsCMatRep and IsMatrix and IsMutable, IsPosInt],
  function(m,pos)
    if pos = m!.len then
        Unbind(m!.rows[m!.len+1]);
        m!.len := m!.len-1;
    else
        Error("Unbind: not possible for cmats except last entry");
    fi;
  end);


#############################################################################
# CopySubMatrix and ExtractSubMatrix:
#############################################################################

InstallGlobalFunction( CVEC_CopySubMatrix,
function(src,dst,srcli,dstli,srcpos,len,dstpos)
  local i;
  if not(IsIdenticalObj(src!.scaclass,dst!.scaclass)) then
      Error("CVEC_CopySubMatrix: cmats not over common field");
      return;
  fi;
  if Length(srcli) <> Length(dstli) then
      Error("CVEC_CopySubMatrix: row lists do not have equal lengths");
      return;
  fi;
  if srcpos < 1 or srcpos+len-1 > src!.vecclass![CVEC_IDX_len] or len <= 0 then
      Error("CVEC_CopySubMatrix: source area not valid");
      return;
  fi;
  if dstpos < 1 or dstpos+len-1 > dst!.vecclass![CVEC_IDX_len] then
      Error("CVEC_CopySubMatrix: destination area not valid");
      return;
  fi;
  if not(IsMutable(dst)) then
      Error("CVEC_CopySubMatrix: destination is immutable");
      return;
  fi;
  for i in [1..Length(srcli)] do
      CVEC_SLICE(src!.rows[srcli[i]+1],dst!.rows[dstli[i]+1],
                 srcpos,len,dstpos);
  od;
end );

InstallGlobalFunction( CVEC_CopySubMatrixUgly,
function(src,dst,srows,drows,scols,dcols)
  # This handles the ugly case that scols and dcols are no ranges
  # with increment 1, we try to optimize using SLICE. We already
  # know, that they have equal nonzero length:

  local FindRuns,IntersectRuns,c,i,j,r,s;

  FindRuns := function(l)
    # l must be nonempty
    local c,i,r,s;
    r := [];
    i := 2;
    s := l[1];
    c := l[1];
    while i <= Length(l) do
        if l[i] = c+1 then
            c := c + 1;
        else
            Add(r,s);      # The start of the run
            Add(r,c-s+1);  # The length of the run
            c := l[i];
            s := l[i];
        fi;
        i := i + 1;
    od;
    Add(r,s);
    Add(r,c-s+1);
    return r;
  end;

  IntersectRuns := function(l1,l2)
    # Both are nonempty, the result are two refined runs with equal part 
    # lengths. They are given as one list of triples.
    local i1,i2,newrun,r;
    r := [];
    i1 := 1;
    i2 := 1;
    while i1 <= Length(l1) do
        # Note that i1 <= Length(l1) iff i2 <= Length(l2)
        if l1[i1+1] < l2[i2+1] then
            newrun := l1[i1+1];
            Add(r,l1[i1]);
            Add(r,newrun);
            Add(r,l2[i2]);
            l2[i2] := l2[i2] + newrun;
            l2[i2+1] := l2[i2+1] - newrun;
            i1 := i1 + 2;
        elif l1[i1+1] > l2[i2+1] then
            newrun := l2[i2+1];
            Add(r,l1[i1]);
            Add(r,newrun);
            Add(r,l2[i2]);
            l1[i1] := l1[i1] + newrun;
            l1[i1+1] := l1[i1+1] - newrun;
            i2 := i2 + 2;
        else
            newrun := l1[i1+1];
            Add(r,l1[i1]);
            Add(r,newrun);
            Add(r,l2[i2]);
            i1 := i1 + 2;
            i2 := i2 + 2;
        fi;
    od;
    return r;
  end;

  r := [FindRuns(scols),FindRuns(dcols)];
  r := IntersectRuns(r[1],r[2]);
  
  for i in [1..Length(srows)] do
      j := 1;
      while j <= Length(r) do
          CVEC_SLICE(src[srows[i]],dst[drows[i]],r[j],r[j+1],r[j+2]);
          j := j + 3;
      od;
  od;
end );

InstallOtherMethod( CopySubMatrix, "for two cmats and stuff",
  [IsCMatRep and IsMatrix, IsCMatRep and IsMatrix and IsMutable,
   IsList,IsList,IsList,IsList],
  function( src,dst,srows,drows,scols,dcols )
    if Length(srows) <> Length(drows) then
        Error("CVEC_CopySubMatrix: row lists must have equal length");
    fi;
    if Length(scols) = 0 or Length(srows) = 0 then return; fi;
    if not(ForAll(srows,x->x >= 1 and x <= src!.len) and
           ForAll(drows,x->x >= 1 and x <= dst!.len)) then
        Error("CVEC_CopySubMatrix: row indices out of range");
    fi;
    # These tests ensure that both matrices have at least one row!
    # Not make sure that srows and drows are plain lists:
    if IsRangeRep(srows) then
        srows := 1*srows;  # unpack it!
    fi;
    if IsRangeRep(drows) then
        drows := 1*drows;  # unpack it!
    fi;
    CVEC_COPY_SUBMATRIX(src!.rows,dst!.rows,srows,drows,scols,dcols);
  end );

InstallMethod( ExtractSubMatrix, "for a cmats and stuff",
  [IsCMatRep and IsMatrix, IsList, IsList],
  function( mat, rows, cols )
    local i,l,res,vcl;
    vcl := mat!.vecclass;
    if cols = [1..vcl![CVEC_IDX_len]] then
        l := 0*[1..Length(rows)+1];
        for i in [1..Length(rows)] do
            l[i+1] := ShallowCopy(mat!.rows[rows[i]+1]);
        od;
        return CVEC_CMatMaker(l,vcl);
    elif Length(cols) <> vcl![CVEC_IDX_len] then
        vcl := CVEC_NewCVecClassSameField(vcl,Length(cols));
    fi;
    if not(ForAll(rows,x->x >= 1 and x <= mat!.len)) then
        Error("CVEC_ExtractSubMatrix: row indices out of range");
        return;
    fi;
    # Make rows a plain list:
    res := CVEC_ZeroMat(Length(rows),vcl);
    if Length(rows) = 0 then return res; fi;
    if IsRangeRep(rows) then
        rows := 1*rows;
    fi;
    CVEC_COPY_SUBMATRIX( mat!.rows, res!.rows,rows,1*[1..Length(rows)],
                         cols, [1..Length(cols)] );
    return res;
  end );

InstallMethod( ExtractSubMatrix, "for a compressed gf2 matrix",
  [IsMatrix and IsGF2MatrixRep, IsList, IsList],
  function(m, rows, cols)
    local mm;
    mm := m{rows}{cols};
    ConvertToMatrixRep(mm,2);
    return mm;
  end );

InstallMethod( ExtractSubMatrix, "for a compressed 8bit matrix",
  [IsMatrix and Is8BitMatrixRep, IsList, IsList],
  function(m, rows, cols)
    local mm,s;
    mm := m{rows}{cols};
    s := Size(BaseField(m));
    ConvertToMatrixRep(mm,s);
    return mm;
  end );


#############################################################################
# Arithmetic for matrices:
#############################################################################

InstallOtherMethod( \+, "for cmats", 
  [IsCMatRep and IsMatrix, IsCMatRep and IsMatrix],
  function(m,n)
    local l,res,i;
    if not(IsIdenticalObj(m!.vecclass,n!.vecclass)) then
        Error("\\+: cmats not compatible");
    fi;
    if m!.len <> n!.len then
        Error("\\+: cmats do not have equal length");
    fi;
    l := 0*[1..m!.len+1];
    for i in [2..m!.len+1] do
	l[i] := ShallowCopy(m!.rows[i]);
	CVEC_ADD2(l[i],n!.rows[i],0,0);
    od;
    res := CVEC_CMatMaker(l,m!.vecclass);
    if not(IsMutable(m)) and not(IsMutable(n)) then
        MakeImmutable(res);
    fi;
    return res;
  end);

InstallOtherMethod( \-, "for cmats", 
  [IsCMatRep and IsMatrix, IsCMatRep and IsMatrix],
  function(m,n)
    local l,res,p,i;
    if not(IsIdenticalObj(m!.vecclass,n!.vecclass)) then
        Error("\\-: cmats not compatible");
    fi;
    if m!.len <> n!.len then
        Error("\\-: cmats do not have equal length");
    fi;
    p := m!.vecclass![CVEC_IDX_fieldinfo]![CVEC_IDX_p];
    l := 0*[1..m!.len+1];
    for i in [2..m!.len+1] do
	l[i] := ShallowCopy(m!.rows[i]);
	CVEC_ADDMUL(l[i],n!.rows[i],p-1,0,0);
    od;
    res := CVEC_CMatMaker(l,m!.vecclass);
    if not(IsMutable(m)) and not(IsMutable(n)) then
        MakeImmutable(res);
    fi;
    return res;
  end);

InstallOtherMethod( AdditiveInverseSameMutability, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local l,res,i;
    l := 0*[1..m!.len+1];
    for i in [2..m!.len+1] do
	l[i] := -m!.rows[i];
    od;
    res := CVEC_CMatMaker(l,m!.vecclass);
    if not(IsMutable(m)) then
        MakeImmutable(res);
    fi;
    return res;
  end);
InstallOtherMethod( AdditiveInverseMutable, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local l,i;
    l := 0*[1..m!.len+1];
    for i in [2..m!.len+1] do
	l[i] := AdditiveInverseMutable(m!.rows[i]);
    od;
    return CVEC_CMatMaker(l,m!.vecclass);
  end);

InstallOtherMethod( ZeroImmutable, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local i,l,res,v;
    l := [0];
    v := CVEC_NEW(m!.vecclass,m!.vecclass![CVEC_IDX_type]);
    MakeImmutable(v);
    for i in [2..m!.len+1] do
        l[i] := v;
    od;
    res := CVEC_CMatMaker(l,m!.vecclass);
    MakeImmutable(res);
    return res;
  end);
InstallOtherMethod( ZeroMutable, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local i,l;
    l := [0];
    for i in [2..m!.len+1] do
        l[i] := CVEC_NEW(m!.vecclass,m!.vecclass![CVEC_IDX_type]);
    od;
    return CVEC_CMatMaker(l,m!.vecclass);
  end);
InstallOtherMethod( ZeroSameMutability, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    if IsMutable(m) then
        return ZeroMutable(m);
    else
        return ZeroImmutable(m);
    fi;
  end);
    
InstallOtherMethod( OneMutable, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local i,l,one,v,w;
    if m!.vecclass![CVEC_IDX_len] <> m!.len then
        #Error("OneMutable: cmat is not square");
        return fail;
    fi;
    v := CVEC_NEW(m!.vecclass,m!.vecclass![CVEC_IDX_type]);
    l := 0*[1..m!.len+1];
    one := One(m!.scaclass);
    for i in [1..m!.len] do
        w := ShallowCopy(v);
        w[i] := one;
        l[i+1] := w;
    od;
    return CVEC_CMatMaker(l,m!.vecclass);
  end);
InstallOtherMethod( OneSameMutability, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local n;
    n := OneMutable(m);
    if not(IsMutable(m)) then
        MakeImmutable(n);
    fi;
    return n;
  end);

#############################################################################
# Multiplication with scalars:
#############################################################################

BindGlobal( "CVEC_MATRIX_TIMES_SCALAR", function(m,s)
    local i,l,res;
    l := 0*[1..m!.len+1];
    s := CVEC_HandleScalar(m!.vecclass,s);
    for i in [2..m!.len+1] do 
        l[i] := CVEC_VECTOR_TIMES_SCALAR(m!.rows[i],s); 
    od;
    res := CVEC_CMatMaker(l,m!.vecclass);
    if not(IsMutable(m)) then
        MakeImmutable(res);
    fi;
    return res;
end );
InstallOtherMethod( \*, "for a cmat", [IsCMatRep and IsMatrix, IsInt], 
  CVEC_MATRIX_TIMES_SCALAR);
InstallOtherMethod( \*, "for a cmat", [IsCMatRep and IsMatrix, IsFFE], 
  CVEC_MATRIX_TIMES_SCALAR);
InstallOtherMethod( \*, "for a cmat", [IsInt,IsCMatRep and IsMatrix], 
  function(s,m) return CVEC_MATRIX_TIMES_SCALAR(m,s); end);
InstallOtherMethod( \*, "for a cmat", [IsFFE,IsCMatRep and IsMatrix], 
  function(s,m) return CVEC_MATRIX_TIMES_SCALAR(m,s); end);


#############################################################################
# Comparison:
#############################################################################

InstallOtherMethod( \=, "for two cmats",
  [IsCMatRep and IsMatrix, IsCMatRep and IsMatrix],
  function(m,n)
    local i;
    if not(IsIdenticalObj(m!.vecclass,n!.vecclass)) or m!.len <> n!.len then
        return false;
    fi;
    for i in [2..m!.len+1] do
        if m!.rows[i] <> n!.rows[i] then
            return false;
        fi;
    od;
    return true;
  end);

InstallOtherMethod( \<, "for two cmats",
  [IsCMatRep and IsMatrix, IsCMatRep and IsMatrix],
  function(m,n)
    local i;
    if not(IsIdenticalObj(m!.vecclass,n!.vecclass)) or m!.len <> n!.len then
        return fail;
    fi;
    for i in [2..m!.len+1] do
        if m!.rows[i] < n!.rows[i] then 
            return true;
        elif n!.rows[i] < m!.rows[i] then
            return false;
        fi;
    od;
    return false;
  end);

InstallOtherMethod( IsZero, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    return ForAll(m!.rows,IsZero);
  end);

InstallOtherMethod( IsOne, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    local i,v;
    if m!.vecclass![CVEC_IDX_len] <> m!.len then
        return false;
    fi;
    for i in [1..m!.len] do
        if not(IsOne(m!.rows[i+1][i])) then
            return false;
        fi;
        v := ShallowCopy(m!.rows[i+1]);
        v[i] := 0;
        if not(IsZero(v)) then
            return false;
        fi;
    od;
    return true;
  end );


#############################################################################
# Access to the base field:
#############################################################################

InstallOtherMethod( Characteristic, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    return m!.vecclass![CVEC_IDX_fieldinfo]![CVEC_IDX_p];
  end);
    
InstallOtherMethod( DegreeFFE, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    return m!.vecclass![CVEC_IDX_fieldinfo]![CVEC_IDX_d];
  end);
    
InstallMethod( BaseDomain, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    local c;
    c := m!.vecclass;
    return c![CVEC_IDX_GF];
  end);
    
InstallMethod( BaseField, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    local c;
    c := m!.vecclass;
    return c![CVEC_IDX_GF];
  end);
    
InstallMethod(FieldOfMatrixList,
  [IsListOrCollection and IsFFECollCollColl],1,
  function(l)
    local char,deg,m;
    if Length(l) = 0 then
        TryNextMethod();
    fi;
    if not(IsCMatRep(l[1])) then
        TryNextMethod();
    fi;
    deg := 1;
    char := Characteristic(l[1]);
    for m in l do
        deg := Lcm(deg,DegreeFFE(m));
        if char <> Characteristic(m) then
            Error("not all matrices over field with same characteristic");
        fi;
    od;
    return GF(char,deg);
  end);

InstallMethod(DefaultFieldOfMatrix,
  [IsMatrix and IsCMatRep and IsFFECollColl],
  function(m)
    local f;
    return m!.vecclass![CVEC_IDX_GF];
  end);

#############################################################################
# The making of good hash functions:
#############################################################################

InstallGlobalFunction( CVEC_HashFunctionForCMats, function(x,data)
  local i,res;
  res := 0;
  for i in [2..x!.len+1] do
      res := (res * 1001 + CVEC_HashFunctionForCVecs(x!.rows[i],data)) 
             mod data[1]+1;
  od;
  return res;
end );

InstallMethod( ChooseHashFunction, "for cmats",
  [IsCMatRep,IsInt],
  function(p,hashlen)
    local bytelen,cl;
    cl := p!.vecclass;
    bytelen := cl![CVEC_IDX_wordlen] * CVEC_BYTESPERWORD;
    return rec( func := CVEC_HashFunctionForCMats,
                data := [hashlen,bytelen] );
  end );


#############################################################################
# Greasing:
#############################################################################

InstallValue( CVEC_SpreadTabCache, [] );

InstallGlobalFunction( CVEC_MakeSpreadTab, function(p,d,l,bitsperel)
    # Make up the spreadtab (EXTRACT values are 2^bitsperel-adic
    # expansions with digits only between 0 and p-1):
    local dim,e,i,j,k,mm,pot,spreadtab;
    if IsBound(CVEC_SpreadTabCache[p]) and
       IsBound(CVEC_SpreadTabCache[p][d]) and
       IsBound(CVEC_SpreadTabCache[p][d][l]) then
        return CVEC_SpreadTabCache[p][d][l];
    fi;
    spreadtab := [];
    dim := d*l;
    e := 0*[1..dim+1];
    j := 0;
    mm := 2^bitsperel;
    for i in [0..p^dim-1] do
        spreadtab[j+1] := i+1;
        # Now increment expansion as a p-adic expansion and modify
        # j accordingly as the value of the corresponding m-adic
        # expansion:
        k := 1;
        pot := 1;
        while true do 
            e[k] := e[k] + 1;
            j := j + pot;
            if e[k] < p then break; fi;
            e[k] := 0;
            j := j - p*pot;
            k := k + 1;
            pot := pot * mm;
        od;
    od;
    if not(IsBound(CVEC_SpreadTabCache[p])) then
        CVEC_SpreadTabCache[p] := [];
    fi;
    if not(IsBound(CVEC_SpreadTabCache[p][d])) then
        CVEC_SpreadTabCache[p][d] := [];
    fi;
    CVEC_SpreadTabCache[p][d][l] := spreadtab;
    return spreadtab;
end );

InstallOtherMethod( GreaseMat, "for a cmat",
  [IsMatrix and IsCMatRep],
  function(m)
    if m!.vecclass![CVEC_IDX_fieldinfo]![CVEC_IDX_bestgrease] = 0 then
        Info(InfoWarning,1,"GreaseMat: bestgrease is 0, we do not grease");
        return;
    fi;
    GreaseMat(m,m!.vecclass![CVEC_IDX_fieldinfo]![CVEC_IDX_bestgrease]);
  end);

InstallMethod( GreaseMat, "for a cmat, and a level", 
  [IsMatrix and IsCMatRep, IsInt],
  function(m,l)
    local bitsperel,d,dim,e,f,i,j,k,mm,nrblocks,p,pot,q,tablen;
    f := m!.vecclass![CVEC_IDX_fieldinfo];   # the field info
    bitsperel := f![CVEC_IDX_bitsperel];
    p := f![CVEC_IDX_p];
    d := f![CVEC_IDX_d];
    q := f![CVEC_IDX_q];
    nrblocks := QuoInt(m!.len+l-1,l);  # we do grease the last <l rows!
    tablen := q^l;  # = p^(d*l)
    m!.greaselev := l;
    m!.greaseblo := nrblocks;
    m!.greasetab := 0*[1..nrblocks];
    for i in [1..nrblocks] do
        m!.greasetab[i] := 0*[1..tablen+1+l];
        for j in [1..tablen+1+l] do
            m!.greasetab[i][j] := 
                CVEC_NEW(m!.vecclass,m!.vecclass![CVEC_IDX_type]);
        od;
        CVEC_FILL_GREASE_TAB(m!.rows,2+(i-1)*l,l,m!.greasetab[i],tablen,1);
    od;

    m!.spreadtab := CVEC_MakeSpreadTab(p,d,l,bitsperel);

    # Finally change the type:
    SetFilterObj(m,HasGreaseTab);
  end); 

InstallMethod( UnGreaseMat, "for a cmat",
  [IsMatrix and IsCMatRep],
  function(m)
    ResetFilterObj(m,HasGreaseTab);
    Unbind(m!.greasetab);
    Unbind(m!.greaselev);
    Unbind(m!.greaseblo);
    Unbind(m!.spreadtab);
  end);

InstallGlobalFunction( CVEC_OptimizeGreaseHint, function(m,nr)
  local l,li,q;
  q := m!.vecclass![CVEC_IDX_fieldinfo]![CVEC_IDX_q];
  li := [QuoInt(nr*(q-1)*m!.len + (q-1),q)];
  l := 1;
  while l < 12 do
      li[l+1] := QuoInt(m!.len + (l-1),l)*(nr+q^l);
      if l > 1 and li[l+1] > li[l] then break; fi;
      l := l + 1;
  od;
  if li[l] < li[1] then
      m!.greasehint := l-1;
  else
      m!.greasehint := 0;
  fi;
  #Print("OptimizeGreaseHint: ",li," ==> ",m!.greasehint,"\n");
end );


#############################################################################
# Arithmetic between vectors and matrices, especially multiplication:
#############################################################################
    
InstallOtherMethod(\*, "for a cvec and a cmat, without greasing",
  [IsCVecRep, IsCMatRep and IsMatrix],
  function(v,m)
    local i,res,vcl,s,z;
    vcl := DataType(TypeObj(v));
    if not(IsIdenticalObj(vcl![CVEC_IDX_fieldinfo],
                          m!.vecclass![CVEC_IDX_fieldinfo])) then
        Error("\\*: incompatible base fields");
    fi;
    if Length(v) <> m!.len then
        Error("\\*: lengths not equal");
    fi;
    res := CVEC_NEW(m!.vecclass,m!.vecclass![CVEC_IDX_type]);  # the result
    CVEC_PROD_CVEC_CMAT_NOGREASE(res,v,m!.rows);
    if not(IsMutable(v) or IsMutable(m)) then
        MakeImmutable(res);
    fi;
    return res;
  end);
 
InstallOtherMethod(\^, "for a cvec and a cmat, without greasing",
  [IsCVecRep, IsCMatRep and IsMatrix],
  function(v,m)
    local i,res,vcl,s,z;
    vcl := DataType(TypeObj(v));
    if not(IsIdenticalObj(vcl![CVEC_IDX_fieldinfo],
                          m!.vecclass![CVEC_IDX_fieldinfo])) then
        Error("\\^: incompatible base fields");
    fi;
    if Length(v) <> m!.len then
        Error("\\^: lengths not equal");
    fi;
    res := CVEC_NEW(m!.vecclass,m!.vecclass![CVEC_IDX_type]);  # the result
    CVEC_PROD_CVEC_CMAT_NOGREASE(res,v,m!.rows);
    if not(IsMutable(v) or IsMutable(m)) then
        MakeImmutable(res);
    fi;
    return res;
  end);
 
InstallOtherMethod(\*, "for a cvec and a greased cmat",
  [IsCVecRep, IsCMatRep and IsMatrix and HasGreaseTab],
  function(v,m)
    local i,res,vcl,l,pos,val;
    vcl := DataType(TypeObj(v));
    if not(IsIdenticalObj(vcl![CVEC_IDX_fieldinfo],
                          m!.vecclass![CVEC_IDX_fieldinfo])) then
        Error("\\*: incompatible base fields");
    fi;
    if Length(v) <> m!.len then
        Error("\\*: lengths not equal");
    fi;
    res := CVEC_NEW(m!.vecclass,m!.vecclass![CVEC_IDX_type]);  # the result
    CVEC_PROD_CVEC_CMAT_GREASED(res,v,m!.greasetab,m!.spreadtab,m!.greaselev);
    if not(IsMutable(v) or IsMutable(m)) then
        MakeImmutable(res);
    fi;
    return res;
  end);
 
InstallOtherMethod(\^, "for a cvec and a greased cmat",
  [IsCVecRep, IsCMatRep and IsMatrix and HasGreaseTab],
  function(v,m)
    local i,res,vcl,l,pos,val;
    vcl := DataType(TypeObj(v));
    if not(IsIdenticalObj(vcl![CVEC_IDX_fieldinfo],
                          m!.vecclass![CVEC_IDX_fieldinfo])) then
        Error("\\^: incompatible base fields");
    fi;
    if Length(v) <> m!.len then
        Error("\\^: lengths not equal");
    fi;
    res := CVEC_NEW(m!.vecclass,m!.vecclass![CVEC_IDX_type]);  # the result
    CVEC_PROD_CVEC_CMAT_GREASED(res,v,m!.greasetab,m!.spreadtab,m!.greaselev);
    if not(IsMutable(v) or IsMutable(m)) then
        MakeImmutable(res);
    fi;
    return res;
  end);
 
InstallOtherMethod(\*, "for two cmats, second one not greased",
  [IsCMatRep and IsMatrix, IsCMatRep and IsMatrix],
  function(m,n)
    local greasetab,i,j,l,lev,res,spreadtab,tablen,vcl,q,d;
    if not(IsIdenticalObj(m!.scaclass,n!.scaclass)) then
        Error("\\*: incompatible base fields");
    fi;
    if m!.vecclass![CVEC_IDX_len] <> n!.len then
        Error("\\*: lengths not matching");
    fi;
    # First make a new matrix:
    l := 0*[1..m!.len+1];
    vcl := n!.vecclass;
    for i in [2..m!.len+1] do
        l[i] := CVEC_NEW(vcl,vcl![CVEC_IDX_type]);
    od;
    res := CVEC_CMatMaker(l,n!.vecclass);
    if m!.len > 0 then
        q := vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_q];
        d := vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_d];
        lev := n!.greasehint;
        if lev = 0 or 
           3 * d * m!.len * (q-1) * lev <= (m!.len + q^lev) * q then   
           # the old - very bad - formula: (extremely bad for lev=1!)
           #m!.len * (q-1) * lev <= (m!.len + q^lev) * q then   
           # This formula is a compromise: We want to grease already for
           # smaller matrices since we cannot predict the performance of
           # scalar multiplication nicely. Thus we added the factor
           # here. This is heuristics!
            # no greasing at all in this case!
            CVEC_PROD_CMAT_CMAT_NOGREASE2(l,m!.rows,n!.rows);
            # we use version 2, which unpacks full rows of m instead of
            # extracting single field entries.
        else
            spreadtab := CVEC_MakeSpreadTab(
                 vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_p],
                 vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_d],
                 lev, vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_bitsperel]);
            tablen := vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_q]^lev;
            greasetab := 0*[1..tablen+1+lev];
            for j in [1..tablen+1+lev] do
              greasetab[j] := CVEC_NEW(n!.vecclass,n!.vecclass![CVEC_IDX_type]);
            od;
            CVEC_PROD_CMAT_CMAT_WITHGREASE(l,m!.rows,n!.rows,greasetab,
                                           spreadtab,lev);
        fi;
    fi;
    if not(IsMutable(m) or IsMutable(n)) then
        MakeImmutable(res);
    fi;
    return res;
  end);

InstallOtherMethod(\*, "for two cmats, second one greased",
  [IsCMatRep and IsMatrix, IsCMatRep and IsMatrix and HasGreaseTab],
  function(m,n)
    local i,l,res,vcl;
    if not(IsIdenticalObj(m!.scaclass,n!.scaclass)) then
        Error("\\*: incompatible base fields");
    fi;
    if m!.vecclass![CVEC_IDX_len] <> n!.len then
        Error("\\*: lengths not matching");
    fi;
    # First make a new matrix:
    l := 0*[1..m!.len+1];
    vcl := n!.vecclass;
    for i in [2..m!.len+1] do
        l[i] := CVEC_NEW(vcl,vcl![CVEC_IDX_type]);
    od;
    res := CVEC_CMatMaker(l,n!.vecclass);
    if m!.len > 0 then
        CVEC_PROD_CMAT_CMAT_GREASED(l,m!.rows,n!.greasetab,n!.spreadtab,
                                    n!.len,n!.greaselev);
    fi;
    if not(IsMutable(m)) and not(IsMutable(n)) then
        MakeImmutable(res);
    fi;
    return res;
  end);

#############################################################################
# Inversion of matrices:
#############################################################################

BindGlobal( "CVEC_INVERT_FFE",function(helper)
  helper[1] := helper[1]^-1;
end );

InstallGlobalFunction( CVEC_InverseWithoutGrease, function(m)
    # Now make a new identity matrix:
    local helper,i,l,mc,mi,vcl;
    vcl := m!.vecclass;
    l := [0];
    for i in [m!.len+1,m!.len..2] do
        l[i] := CVEC_NEW(vcl,vcl![CVEC_IDX_type]);
        l[i][i-1] := 1;   # note that this works for all fields!
    od;
    mi := CVEC_CMatMaker(l,vcl);
    # Now make a copy of the matrix:
    mc := MutableCopyMat(m);

    # Now do the real work:
    helper := CVEC_New(vcl);
    i := CVEC_CMAT_INVERSE(mi!.rows,mc!.rows,CVEC_INVERT_FFE,helper);

    if i <> fail then
        return mi;
    else
        return fail;
    fi;
  end );

InstallGlobalFunction (CVEC_InverseWithGrease,
  function(m,lev)
    local greasetab1,greasetab2,helper,i,l,mc,mi,spreadtab,tablen,vcl;
    vcl := m!.vecclass;
    if m!.len <> vcl![CVEC_IDX_len] then return fail; fi;
    if m!.len = 0 then return fail; fi;
    if m!.len = 1 then
        l := [0,CVEC_New(vcl)];
        i := m!.rows[2][1]^-1;
        if i = fail then
            return fail;
        fi;
        l[2][1] := i;
        return CVEC_CMatMaker(l,m!.vecclass);
    fi;
    # Now make a new identity matrix:
    l := [0];
    for i in [m!.len+1,m!.len..2] do
        l[i] := CVEC_NEW(vcl,vcl![CVEC_IDX_type]);
        l[i][i-1] := 1;   # note that this works for all fields!
    od;
    mi := CVEC_CMatMaker(l,vcl);
    # Now make a copy of the matrix:
    mc := MutableCopyMat(m);

    # Prepare to grease:
    spreadtab := CVEC_MakeSpreadTab(
         vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_p],
         vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_d],
         lev, vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_bitsperel]);
    tablen := vcl![CVEC_IDX_fieldinfo]![CVEC_IDX_q]^lev;
    greasetab1 := 0*[1..tablen+1+lev];
    greasetab2 := 0*[1..tablen+1+lev];
    for i in [1..tablen+1+lev] do
      greasetab1[i] := CVEC_NEW(vcl,vcl![CVEC_IDX_type]);
      greasetab2[i] := CVEC_NEW(vcl,vcl![CVEC_IDX_type]);
    od;

    # Now do the real work:
    helper := CVEC_New(vcl);
    i := CVEC_CMAT_INVERSE_GREASE(mi!.rows,mc!.rows,CVEC_INVERT_FFE,helper,
                                  [greasetab1,greasetab2,spreadtab,lev,tablen]);

    if i <> fail then
        return mi;
    else
        return fail;
    fi;
  end );

InstallOtherMethod( InverseMutable, "for a square cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local i,l,vcl;
    vcl := m!.vecclass;
    if m!.len <> vcl![CVEC_IDX_len] then return fail; fi;
    if m!.len = 0 then return fail; fi;
    if m!.len = 1 then
        l := [0,CVEC_New(vcl)];
        i := m!.rows[2][1]^-1;
        if i = fail then
            return fail;
        fi;
        l[2][1] := i;
        return CVEC_CMatMaker(l,m!.vecclass);
    fi;
    if m!.greasehint = 0 or m!.len < 100 then
        return CVEC_InverseWithoutGrease(m);
    else
        return CVEC_InverseWithGrease(m,m!.greasehint);
    fi;
  end );

InstallOtherMethod( InverseSameMutability, "for a square cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local mi;
    mi := InverseMutable(m);
    if mi <> fail and not(IsMutable(m)) then
        MakeImmutable(mi);
    fi;
    return mi;
  end );


#############################################################################
# Transposition:
#############################################################################

InstallOtherMethod( TransposedMatOp, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    # First make a new matrix:
    local c,ct,i,l,mt,newlen;
    c := m!.vecclass;
    ct := CVEC_NewCVecClassSameField(c,m!.len);
    newlen := c![CVEC_IDX_len];
    l := 0*[1..newlen+1];
    for i in [2..newlen+1] do
        l[i] := CVEC_NEW(ct,ct![CVEC_IDX_type]);
    od;
    mt := CVEC_CMatMaker(l,ct);
    if m!.len > 0 and mt!.len > 0 then
        CVEC_TRANSPOSED_MAT(m!.rows,mt!.rows);
    fi;
    return mt;
  end);

InstallOtherMethod( TransposedMat, "for a cmat",
  [IsCMatRep and IsMatrix],
  function(m)
    local mt;
    mt := TransposedMatOp(m);
    MakeImmutable(mt);
    return mt;
  end);

#############################################################################
# I/O for Matrices:
#############################################################################

BindGlobal( "CVEC_64BIT_NUMBER_TO_STRING_LITTLE_ENDIAN", function(n)
  local i,s;
  s := "        ";
  for i in [1..8] do
      s[i] := CHAR_INT(RemInt(n,256));
      n := QuoInt(n,256);
  od;
  return s;
end );

InstallGlobalFunction( CVEC_WriteMat, function(f,m)
  local buf,c,chead,dhead,header,i,magic,phead,rhead;
  if not(IsFile(f)) then
      Error("CVEC_WriteMat: first argument must be a file");
      return fail;
  fi;
  if not(IsCMatRep(m)) then
      Error("CVEC_WriteMat: second argument must be a cmat");
      return fail;
  fi;
  c := m!.vecclass;
  Info(InfoCVec,2,"CVEC_WriteMat: Writing ",m!.len,"x",
       c![CVEC_IDX_len]," matrix over GF(",
       c![CVEC_IDX_fieldinfo]![CVEC_IDX_p],",",
       c![CVEC_IDX_fieldinfo]![CVEC_IDX_d],")");
  # Make the header:
  magic := "GAPCMat1";
  phead := CVEC_64BIT_NUMBER_TO_STRING_LITTLE_ENDIAN(
           c![CVEC_IDX_fieldinfo]![CVEC_IDX_p]);
  dhead := CVEC_64BIT_NUMBER_TO_STRING_LITTLE_ENDIAN(
           c![CVEC_IDX_fieldinfo]![CVEC_IDX_d]);
  rhead := CVEC_64BIT_NUMBER_TO_STRING_LITTLE_ENDIAN(m!.len);
  chead := CVEC_64BIT_NUMBER_TO_STRING_LITTLE_ENDIAN(
           c![CVEC_IDX_len]);
  header := Concatenation(magic,phead,dhead,rhead,chead);
  if IO_Write(f,header) <> 40 then
      Info(InfoCVec,1,"CVEC_WriteMat: Write error during writing of header");
      return fail;
  fi;
  buf := "";  # will be made longer automatically
  for i in [1..m!.len] do
      CVEC_CVEC_TO_EXTREP(m!.rows[i+1],buf);
      if IO_Write(f,buf) <> Length(buf) then
          Info(InfoCVec,1,"CVEC_WriteMat: Write error");
          return fail;
      fi;
  od;
  return true;
end );

InstallGlobalFunction( CVEC_WriteMatToFile, function(fn,m)
  local f;
  f := IO_File(fn,"w");
  if f = fail then
      Info(InfoCVec,1,"CVEC_WriteMatToFile: Cannot create file");
      return fail;
  fi;
  if CVEC_WriteMat(f,m) = fail then return fail; fi;
  if IO_Close(f) = fail then
      Info(InfoCVec,1,"CVEC_WriteMatToFile: Cannot close file");
      return fail;
  fi;
  return true;
end );

InstallGlobalFunction( CVEC_WriteMatsToFile, function(fnpref,l)
  local i;
  if not(IsString(fnpref)) then
      Error("CVEC_WriteMatsToFile: fnpref must be a string");
      return fail;
  fi;
  if not(IsList(l)) then
      Error("CVEC_WriteMatsToFile: l must be list");
      return fail;
  fi;
  for i in [1..Length(l)] do
      if CVEC_WriteMatToFile(Concatenation(fnpref,String(i)),l[i]) = fail then
          return fail;
      fi;
  od;
  return true;
end );

BindGlobal( "CVEC_STRING_LITTLE_ENDIAN_TO_64BIT_NUMBER", function(s)
  local i,n;
  n := 0;
  for i in [8,7..1] do
      n := n * 256 + INT_CHAR(s[i]);
  od;
  return n;
end );

InstallGlobalFunction( CVEC_ReadMat, function(f)
  local buf,c,cols,d,header,i,len,m,p,rows;
  if not(IsFile(f)) then
      Error("CVEC_ReadMat: first argument must be a file");
      return fail;
  fi;
  header := IO_ReadBlock(f,40);
  if Length(header) < 40 then
      Info(InfoCVec,1,"CVEC_ReadMat: Cannot read header");
      return fail;
  fi;

  # Check and process the header:
  if header{[1..8]} <> "GAPCMat1" then
      Info(InfoCVec,1,"CVEC_ReadMat: Magic of header incorrect");
      return fail;
  fi;
  p := CVEC_STRING_LITTLE_ENDIAN_TO_64BIT_NUMBER(header{[9..16]});
  d := CVEC_STRING_LITTLE_ENDIAN_TO_64BIT_NUMBER(header{[17..24]});
  rows := CVEC_STRING_LITTLE_ENDIAN_TO_64BIT_NUMBER(header{[25..32]});
  cols := CVEC_STRING_LITTLE_ENDIAN_TO_64BIT_NUMBER(header{[33..40]});
  Info(InfoCVec,2,"CVEC_ReadMat: Reading ",rows,"x",cols," matrix over GF(",
       p,",",d,")");
   
  c := CVEC_NewCVecClass(p,d,cols);
  m := CVEC_ZeroMat(rows,c);
  buf := "";  # will be made longer automatically
  if rows > 0 then
      CVEC_CVEC_TO_EXTREP(m!.rows[2],buf);   # to get the length right
      len := Length(buf);
  else
      len := 0;
  fi;

  for i in [1..rows] do
      buf := IO_ReadBlock(f,len);
      if len <> Length(buf) then
          Info(InfoCVec,1,"CVEC_ReadMat: Read error");
          Error();
          return fail;
      fi;
      CVEC_EXTREP_TO_CVEC(buf,m!.rows[i+1]);
  od;
  return m;
end );

InstallGlobalFunction( CVEC_ReadMatFromFile, function(fn)
  local f,m;
  f := IO_File(fn,"r");
  if f = fail then
      Info(InfoCVec,1,"CVEC_ReadMatFromFile: Cannot open file");
      return fail;
  fi;
  m := CVEC_ReadMat(f);
  if m = fail then return fail; fi;
  IO_Close(f);
  return m;
end );

InstallGlobalFunction( CVEC_ReadMatsFromFile, function(fnpref)
  local f,i,l,m;
  if not(IsString(fnpref)) then
      Error("CVEC_ReadMatsFromFile: fnpref must be a string");
      return fail;
  fi;
  f := IO_File(Concatenation(fnpref,"1"),"r");
  if f = fail then
      Error("CVEC_ReadMatsFromFile: no matrices there");
      return fail;
  else
      IO_Close(f);
  fi;
  l := [];
  i := 1;
  while true do
      f := IO_File(Concatenation(fnpref,String(i)),"r");
      if f = fail then break; fi;
      IO_Close(f);
      m := CVEC_ReadMatFromFile(Concatenation(fnpref,String(i)));
      if m = fail then
          return fail;
      else
          Add(l,m);
          i := i + 1;
      fi;
  od;
  return l;
end );

#############################################################################
# Further handling of matrices: 
#############################################################################

InstallMethod( PositionNonZero, "for a cmat",
  [ IsCMatRep and IsMatrix and IsMatrixObj ],
  function(m)
    local i;
    i := 1;
    while i <= m!.len and IsZero(m!.rows[i+1]) do i := i + 1; od;
    return i;
  end );

InstallMethod( PositionNonZero, "for a cmat, and an integer",
  [ IsCMatRep and IsMatrix, IsInt ],
  function(m,j)
    local i;
    i := Maximum(j+1,1);
    while i <= m!.len and IsZero(m!.rows[i+1]) do i := i + 1; od;
    if i > m!.len then
        return m!.len + 1;
    else
        return i;
    fi;
  end );

InstallMethod( PositionLastNonZero, "for a cmat",
  [ IsCMatRep and IsMatrix and IsMatrixObj ],
  function(m)
    local i;
    i := m!.len;;
    while i >= 1 and IsZero(m!.rows[i+1]) do i := i - 1; od;
    return i;
  end );

InstallMethod( PositionLastNonZero, "for a cmat, and an integer",
  [ IsCMatRep and IsMatrix and IsMatrixObj, IsInt ],
  function(m,j)
    local i;
    i := Minimum(j-1,m!.len);
    while i >= 1 and IsZero(m!.rows[i+1]) do i := i - 1; od;
    return i;
  end );

InstallMethod( IsDiagonalMat, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    local i,mi;
    mi := Minimum(m!.len,m!.vecclass![CVEC_IDX_len]);
    i := 1;
    while i <= mi do
        if PositionNonZero(m!.rows[i+1]) < i or
           PositionLastNonZero(m!.rows[i+1]) > i then
            return false;
        fi;
        i := i + 1;
    od;
    while i <= m!.len do
        if not(IsZero(m!.rows[i+1])) then
            return false;
        fi;
        i := i + 1;
    od;
    return true;
  end);

InstallMethod( IsUpperTriangularMat, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    local i,mi;
    mi := Minimum(m!.len,m!.vecclass![CVEC_IDX_len]);
    i := 1;
    while i <= mi do
        if PositionNonZero(m!.rows[i+1]) < i then
            return false;
        fi;
        i := i + 1;
    od;
    while i <= m!.len do
        if not(IsZero(m!.rows[i+1])) then
            return false;
        fi;
        i := i + 1;
    od;
    return true;
  end);

InstallMethod( IsLowerTriangularMat, "for a cmat", [IsCMatRep and IsMatrix],
  function(m)
    local i,mi;
    mi := Minimum(m!.len,m!.vecclass![CVEC_IDX_len]);
    i := 1;
    while i <= mi do
        if PositionLastNonZero(m!.rows[i+1]) > i then
            return false;
        fi;
        i := i + 1;
    od;
    while i <= m!.len do
        if not(IsZero(m!.rows[i+1])) then
            return false;
        fi;
        i := i + 1;
    od;
    return true;
  end);

#############################################################################
# Copying of matrices:
#############################################################################

InstallMethod( MutableCopyMat, "for a cmat", 
  [IsCMatRep and IsMatrixObj],
  function(m)
    local l,i;
    l := 0*[1..m!.len+1];
    for i in [2..m!.len+1] do
        l[i] := ShallowCopy(m!.rows[i]);
    od;
    Unbind(l[1]);
    return CVEC_CMatMaker(l,m!.vecclass);
  end);

#############################################################################
# KroneckerProduct:
#############################################################################

InstallMethod( KroneckerProduct, "for cmats", 
               [ IsCMatRep and IsMatrixObj, IsCMatRep and IsMatrixObj ],
  function( A, B )
    local rowsA, rowsB, colsA, colsB, newclass, AxB, i, j;
      rowsA := Length(A);
      colsA := Length(A[1]);
      rowsB := Length(B);
      colsB := Length(B[1]);

      newclass := CVecClass( A[1], colsA * colsB );
      AxB := CVEC_ZeroMat( rowsA * rowsB, newclass );

      # Cache matrices
      # not implemented yet

      for i in [1..rowsA] do
	for j in [1..colsA] do
	  CopySubMatrix( A[i][j] * B, AxB, 
			 [ 1 .. rowsB ], [ rowsB * (i-1) + 1 .. rowsB * i ],                             [ 1 .. colsB ], [ (j-1) * colsB + 1 .. j * colsB ] );
	od;
      od;
      return AxB;
    end );

#############################################################################
# Folding of matrices and vectors:
#############################################################################

InstallMethod( Unfold, "for a cmat",
  [ IsCMatRep and IsMatrixObj, IsCVecRep ],
  function( m, w )
    local cl,i,v,vcl,x,y;
    cl := m!.vecclass;
    x := cl![CVEC_IDX_len];
    y := m!.len;
    vcl := CVEC_NewCVecClassSameField(cl,x*y);
    v := CVEC_New(vcl);
    for i in [1..y] do
        CVEC_SLICE(m!.rows[i+1],v,1,x,x*(i-1)+1);
    od;
    return v;
  end );

InstallMethod( Fold, "for a cvec and an integer",
  [ IsCVecRep, IsPosInt, IsCMatRep ],
  function( v, x, m )
    local cl,i,l,len,q,vcl,w;
    vcl := DataType(TypeObj(v));
    cl := CVEC_NewCVecClassSameField( vcl, x );
    len := vcl![CVEC_IDX_len];
    q := QuotientRemainder(len,x);
    if q[2] <> 0 then
        Error("x must be a divisor of the length of v");
        return;
    fi;
    q := q[1];
    l := 0*[q+1];
    for i in [2..q+1] do
        w := CVEC_New(cl);
        CVEC_SLICE(v,w,(i-2)*x+1,x,1);
        l[i] := w;
    od;
    return CVEC_CMatMaker(l,cl);
  end );

#############################################################################
# (Un-)Pickling:
#############################################################################

InstallMethod( IO_Pickle, "for cmats",
  [IsFile, IsCMatRep and IsList],
  function( f, m )
    local tag;
    if IsMutable(m) then tag := "MCMA";
    else tag := "ICMA"; fi;
    if IO_Write(f,tag) = fail then return IO_Error; fi;
    if CVEC_WriteMat( f, m ) = fail then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.MCMA :=
  function( f )
    local m;
    m := CVEC_ReadMat( f );
    if m = fail then return IO_Error; fi;
    return m;
  end;

IO_Unpicklers.ICMA :=
  function( f )
    local m;
    m := CVEC_ReadMat( f );
    if m = fail then return IO_Error; fi;
    MakeImmutable(m);
    return m;
  end;


#############################################################################
# Memory usage information:
#############################################################################

InstallMethod( Memory, "for a cmat", [ IsCMatRep ],
  function( m )
    local bpw,bpb;
    # Bytes per word:
    bpw := GAPInfo.BytesPerVariable;
    # Bytes per bag (in addition to content):
    bpb := 8 + 2*bpw;   # this counts the header and the master pointer!
    if Length(m) = 0 then
        return 2*bpb + SHALLOW_SIZE(m) + SHALLOW_SIZE(m!.rows);
    else
        return 2*bpb + SHALLOW_SIZE(m) + SHALLOW_SIZE(m!.rows)
               + Length(m) * Memory(m!.rows[2]);
    fi;
    # FIXME: this does not include greased data!
  end );


#############################################################################
# Grease calibration:
#############################################################################

CVEC.MaximumGreaseCalibration := 1024;

InstallGlobalFunction( CVEC_ComputeVectorLengthsForCalibration,
  function()
    local bpw,cl,epw,f,i,l,le,lencache,lennocache;
    l := Filtered([2..CVEC.MaximumGreaseCalibration],IsPrimePowerInt);
    le := Length(l);
    for i in [1..le] do
        f := Factors(l[i]);
        l[i] := [f[1],Length(f),l[i]];
    od;
    cl := List([1..le],i->CVecClass(l[i][1],l[i][2],1));
    lencache := 0*[1..le];
    lennocache := 0*[1..le];
    bpw := GAPInfo.BytesPerVariable;
    for i in [1..le] do
        epw := cl[i]![CVEC_IDX_fieldinfo]![CVEC_IDX_elsperword];
        # 64kB is surely in the cache:
        lencache[i] := QuoInt(65536 / bpw * epw,
                              cl[i]![CVEC_IDX_fieldinfo]![CVEC_IDX_d]);
        # 16MB is supposedly out of the cache:
        lennocache[i] := QuoInt(16*1024*1024 / bpw * epw,
                                cl[i]![CVEC_IDX_fieldinfo]![CVEC_IDX_d]);
    od;
    return rec( pdq := l, le := le, lencache := lencache, 
                lennocache := lennocache );
  end );

InstallValue( CVEC_CalibrationTable, [] );

InstallGlobalFunction( CVEC_FastFill,
  function( v )
    local cl,d,e,i,l,p,q,x;
    cl := CVecClass(v);
    p := cl![CVEC_IDX_fieldinfo]![CVEC_IDX_p];
    d := cl![CVEC_IDX_fieldinfo]![CVEC_IDX_d];
    q := cl![CVEC_IDX_fieldinfo]![CVEC_IDX_q];
    x := 1;
    l := Length(v);
    for i in [1..Minimum(Length(v),1000)] do
        v[i] := x;
        x := x + 1;
        if x = q then x := 1; fi;
    od;
    i := 1;
    while 1000*i+1 <= Length(v) do
        e := Minimum(Length(v),1000*(i+1));
        CopySubVector(v,v,[1..e-1000*i],[1000*i+1..e]);
        i := i + 1;
    od;
  end );

InstallGlobalFunction( GreaseCalibration,
  function()
    local CVEC_CalibrationTable,cl,d,gd,i,info,j,mult,p,q,sc,t,t1,t2,t3,v1,
          v2,v3;
    info := CVEC_ComputeVectorLengthsForCalibration();
    gd := rec();
    gd.info := info;
    gd.tfCache := 0*[1..info.le];
    gd.tfNoCache := 0*[1..info.le];
    gd.tfPrimRootCache := 0*[1..info.le];
    gd.tfPrimRootNoCache := 0*[1..info.le];
    for i in [1..info.le] do
        p := info.pdq[i][1];
        d := info.pdq[i][2];
        q := info.pdq[i][3];

        # Make a short vector:
        cl := CVecClass(p,d,info.lencache[i]);

        v1 := CVEC_New(cl);
        CVEC_FastFill(v1);
        v2 := ShallowCopy(v1);
        v3 := CVEC_New(cl);

        # Calibrate mult:
        mult := 0;
        t := Runtime();
        while Runtime()-t < 10 do
            mult := mult + 1;
            CVEC_ADD3(v3,v1,v2);
        od;

        t := Runtime();
        for j in [1..mult] do CVEC_ADD3(v3,v1,v2); od;
        t1 := Runtime() - t;
        if d = 1 then
            t := Runtime();
            sc := 2^Log2Int(p)-1;
            for j in [1..mult] do CVEC_MUL2(v3,v1,sc); od;
            t2 := Runtime() - t;
            gd.tfCache[i] := Maximum(1,QuoInt(t2,t1));
        else
            t := Runtime();
            for j in [1..mult] do CVEC_MUL2(v3,v1,p); od;
            t2 := Runtime() - t;
            t := Runtime();
            for j in [1..mult] do CVEC_ADDMUL(v3,v1,q-1,0,0); od;
            t3 := Runtime()-t;
            gd.tfPrimRootCache[i] := Maximum(1,QuoInt(t2,t1));
            gd.tfCache[i] := Maximum(1,QuoInt(t3,t1));
        fi;

        # Make long vectors:
        cl := CVecClass(p,d,info.lennocache[i]);

        v1 := CVEC_New(cl);
        CVEC_FastFill(v1);
        v2 := ShallowCopy(v1);
        v3 := CVEC_New(cl);

        # Calibrate mult:
        mult := 0;
        t := Runtime();
        while Runtime()-t < 10 do
            mult := mult + 1;
            CVEC_ADD3(v3,v1,v2);
        od;

        t := Runtime();
        for j in [1..mult] do CVEC_ADD3(v3,v1,v2); od;
        t1 := Runtime() - t;
        if d = 1 then
            t := Runtime();
            sc := 2^Log2Int(p)-1;
            for j in [1..mult] do CVEC_MUL2(v3,v1,sc); od;
            t2 := Runtime() - t;
            gd.tfNoCache[i] := Maximum(1,QuoInt(t2,t1));
        else
            t := Runtime();
            for j in [1..mult] do CVEC_MUL2(v3,v1,p); od;
            t2 := Runtime() - t;
            t := Runtime();
            for j in [1..mult] do CVEC_ADDMUL(v3,v1,q-1,0,0); od;
            t3 := Runtime()-t;
            gd.tfPrimRootNoCache[i] := Maximum(1,QuoInt(t2,t1));
            gd.tfNoCache[i] := Maximum(1,QuoInt(t3,t1));
        fi;
        Print(i,"/",info.le,"\r");
    od;
    Print("\n");

    # Now we can determine the best grease levels:

    CVEC_CalibrationTable := gd;
    return gd;
  end );



