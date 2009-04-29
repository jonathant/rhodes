package com.rho.db;

import com.xruby.runtime.lang.RubyValue;

public interface IDBResult {
	public abstract int getCount();
	public abstract int getColCount();
	
	public abstract String getColName(int nCol);
	
	public abstract RubyValue getRubyValueByIdx(int nItem, int nCol);
	public abstract long getLongByIdx(int nItem, int nCol);
	public abstract int getIntByIdx(int nItem, int nCol);
	public abstract String getStringByIdx(int nItem, int nCol);
	
	public abstract RubyValue getRubyValue(int nItem, String colname);
	public abstract long getLong(int nItem, String colname);
	public abstract int getInt(int nItem, String colname);
	public abstract String getString(int nItem, String colname);

}
