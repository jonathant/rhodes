package com.rhomobile.rhodes;

import com.rho.sync.SyncThread;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

public class RhoSyncService extends Service {

	@Override
	public IBinder onBind(Intent arg0) {
		return null;
	}
	
	@Override
	public void onCreate() {
		super.onCreate();
	
	}
	
	@Override
	public void onStart(Intent intent, int startId) {
		// Start SyncEngine
		try {
			//SyncEngine.start(null);
			SyncThread.Create( new com.rho.RhoClassFactory() );
			
		} catch (Exception e) {
			Log.e(this.getClass().getSimpleName(), e.getMessage());
		}
	}
	
	@Override
	public void onDestroy() {
		super.onDestroy();
	
		SyncThread.getInstance().Destroy();
	}
	
}
