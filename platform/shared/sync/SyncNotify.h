#pragma once

#include "common/RhoStd.h"
#include "logging/RhoLog.h"

namespace rho {
namespace db {
    class CDBAdapter;
}

namespace net {
    struct INetRequest;
}

namespace sync {
class CSyncEngine;
class CSyncSource;
class CSyncNotify
{
    DEFINE_LOGCLASS;

    struct CSyncNotification
    {
        String m_strUrl, m_strParams;
        CSyncNotification(String strUrl, String strParams) : m_strUrl(strUrl), m_strParams(strParams){}
    };

public:
    enum ENotifyType{ enNone, enDelete, enUpdate, enCreate };

private:

    CSyncEngine& m_syncEngine;

    static String m_strObjectNotifyUrl;
    HashtablePtr<int, Hashtable<String,int>* > m_hashSrcIDAndObject;
    HashtablePtr<int, Hashtable<String,String>* > m_hashCreateObjectErrors;
    String m_strSingleObjectSrcName, m_strSingleObjectID;
    Hashtable<int,int> m_hashSrcObjectCount;

    static common::CMutex m_mxObjectNotify;

    HashtablePtr<int,CSyncNotification*> m_mapSyncNotifications;
    common::CMutex m_mxSyncNotifications;

    net::INetRequest& getNet();
    CSyncEngine& getSync(){ return m_syncEngine; }
    db::CDBAdapter& getDB();
public:
    CSyncNotify( CSyncEngine& syncEngine ) : m_syncEngine(syncEngine){}

    //Object notifications
    void fireObjectsNotification();
    void onObjectChanged(int nSrcID, const String& strObject, int nType);
    void addCreateObjectError(int nSrcID, const String& strObject, const String& strError);

    void addObjectNotify(int nSrcID, const String& strObject );
    void addObjectNotify(const String& strSrcName, const String& strObject );
    static void setObjectNotifyUrl(String strUrl);
    static String getObjectNotifyUrl();
    void cleanObjectNotifications();
    void cleanCreateObjectErrors();

    //Sync notifications
    void setSyncNotification(int source_id, String strUrl, String strParams );
    void clearSyncNotification(int source_id);

    void onSyncSourceEnd( int nSrc, VectorPtr<CSyncSource*>& sources );
    void fireSyncNotification( CSyncSource* psrc, boolean bFinish, int nErrCode, String strMessage);

    void cleanLastSyncObjectCount();
    int incLastSyncObjectCount(int nSrcID);
    int getLastSyncObjectCount(int nSrcID);

private:
    String makeCreateObjectErrorBody(int nSrcID);
    void processSingleObject();

    void doFireSyncNotification( CSyncSource* psrc, boolean bFinish, int nErrCode, String strMessage);
    void reportSyncStatus(String status, int error, String strDetails);
    void fireAllSyncNotifications( boolean bFinish, int nErrCode, String strMessage, VectorPtr<CSyncSource*>& sources );

};

}
}