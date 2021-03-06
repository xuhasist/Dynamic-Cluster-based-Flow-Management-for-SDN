import os
import sys
import json
import time
import arff
import logging
import numpy as np
import pandas as pd
from io import StringIO
from itertools import chain
from multiprocessing import Pool
from collections import OrderedDict

logging.basicConfig(level=logging.DEBUG,  
                    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',  
                    datefmt='%a, %d %b %Y %H:%M:%S',  
                    filename='/tmp/test.log',  
                    filemode='w')  
                    
def main():
    pd.set_option('expand_frame_repr', False)

    inFileName = sys.argv[1]
    
    # read packet traces
    inPkt = loadPcap(inFileName)
    
    del inFileName
    
    inPkt = unicode(inPkt, 'utf-8')
    inPkt = StringIO(inPkt)
    df = pd.read_csv(inPkt, names=['DateTime', 'Timestamp', 'Src_IP', 'Dst_IP', 'Src_Port', 'Dst_Port', \
    'Protocol', 'Length(Bytes)'])

    del inPkt

    df['DateTime'] = df['DateTime'].astype(str)
    df['Timestamp'] = df['Timestamp'].astype(float)
    df['Src_IP'] = df['Src_IP'].astype(str)
    df['Dst_IP'] = df['Dst_IP'].astype(str)
    df['Src_Port'] = df['Src_Port'].astype(int)
    df['Dst_Port'] = df['Dst_Port'].astype(int)
    df['Protocol'] = df['Protocol'].astype(int)
    df['Length(Bytes)'] = df['Length(Bytes)'].astype(int)
    
    #rows = (df['DateTime'] == '2009-12-18 00:37:26.774441')
    #rows = (df['DateTime'] == '2009-12-18 00:29:04.397877')
    #print df.ix[rows]
    #time.sleep(1200)
    
    # 5mins flows
    df = df[853570:1620649]
    
    # 3mins flows
    #df = df[0:11443]
    
    df = df.sort_values(['Protocol', 'Src_IP', 'Dst_IP', 'Src_Port', 'Dst_Port', 'Timestamp'])
    df = df.reset_index(drop=True)
    
    print 'packet counts = ' + str(len(df))

    # unique flow
    df_copy = df.copy()
    df_copy.drop(['DateTime', 'Timestamp', 'Length(Bytes)'], axis=1, inplace=True)
    df_copy = df_copy.drop_duplicates()

    sliceIndex = df_copy.index.values.tolist()
    del sliceIndex[0]
    del df_copy
    
    df_flowSlice = np.array_split(df, sliceIndex)
    del df
    del sliceIndex
    
    pool = Pool(4)
    print 'generate dataframe'
    pktTrace = pool.map(generateAttrFlows, df_flowSlice)
    pool.close()
    
    print 'pool finish'
    pktTrace = filter(None, pktTrace)
    pktTrace = list(chain.from_iterable(pktTrace))
    
    thefile = open('pktTrace_5min.txt', 'w')
    #thefile = open('pktTrace_3min.txt', 'w')
    for item in pktTrace:
        thefile.write("%s\n" % json.dumps(item))
    
    thefile.close()
        
    del pktTrace
    
def loadPcap(inFileName):
    print 'load ' + inFileName

    return os.popen('tshark -r ' + inFileName + ' -Y "(tcp || udp) && !(icmp) && !(ipv6)" -T fields -e _ws.col.DateTime -e _ws.col.Time -e ip.src -e ip.dst -e tcp.srcport -e udp.srcport -e tcp.dstport -e udp.dstport -e ip.proto -e frame.len -E separator=, | tr -s ","').read()
  
def generateAttrFlows(flowSlice):
    logging.info(flowSlice.index[0])
    
    pkt = []
    startLoc = 0

    endLoc = len(flowSlice) - 1
    
    if endLoc == startLoc:
        return pkt   

    attributeFlow = flowTpl()
    
    attributeFlow['transferred_bytes'] = np.sum(flowSlice.iloc[startLoc:endLoc+1]['Length(Bytes)'])
    attributeFlow['duration'] = flowSlice.iloc[endLoc]['Timestamp'] - flowSlice.iloc[startLoc]['Timestamp'] 
    attributeFlow['avg_byte_thr'] = (float)(attributeFlow['transferred_bytes'] / attributeFlow['duration'])
    
    if attributeFlow['duration'] >= 1 and attributeFlow['avg_byte_thr'] >= 1000:
        attr = attrTpl()
        attr['protocol'] = 'TCP' if flowSlice.iloc[startLoc]['Protocol'] == 6 else 'UDP'
        attr['src_port'] = flowSlice.iloc[startLoc]['Src_Port']
        attr['dst_port'] = flowSlice.iloc[startLoc]['Dst_Port']
        attr['duration'] = attributeFlow['duration']
        attr['transferred_bytes'] = attributeFlow['transferred_bytes']
        attr['avg_byte_thr'] = attributeFlow['avg_byte_thr']
    
        send_list = []
        for i in range(startLoc, endLoc+1):
            send = sendTpl()
            send['time'] = flowSlice.iloc[i]['DateTime']
            send['size'] = flowSlice.iloc[i]['Length(Bytes)']
            send_list.append(send)
        
        pktTrace = pktTpl(attr, send_list)
    
        del attr
        del send_list
    
        pktTrace['start_date_time'] = flowSlice.iloc[startLoc]['DateTime']
        pktTrace['end_date_time'] = flowSlice.iloc[endLoc]['DateTime']
        pktTrace['src_ip'] = flowSlice.iloc[startLoc]['Src_IP']
        pktTrace['dst_ip'] = flowSlice.iloc[startLoc]['Dst_IP']
    
        pkt.append(pktTrace)
    
        del pktTrace
    
    del attributeFlow    
    del startLoc
    del endLoc
    del flowSlice
    
    return pkt
    
def flowTpl():
    return OrderedDict([('start_date_time', ""), ('end_date_time', ""), ('srcip', ""), ('dstip', ""), \
    ('portocol', ['TCP', 'UDP']), ('srcport', 0), ('dstport', 0), \
    ('transferred_bytes', 0), ('avg_byte_thr', 0), ('duration', 0)])
    
def attrTpl():
    return OrderedDict([('protocol', ['TCP', 'UDP']), ('src_port', 0), ('dst_port', 0), ('duration', 0), \
    ('transferred_bytes', 0), ('avg_byte_thr', 0)])
    
def sendTpl():
    return OrderedDict([('time', ""), ('size', 0)])
    
def pktTpl(attr, send_list):
    return OrderedDict([('start_date_time', ""), ('end_date_time', ""), ('src_ip', ""), ('dst_ip', ""), \
    ('attr', attr), ('send', send_list)])
    
if __name__ == '__main__':
    print time.strftime('%Y-%m-%d %H:%M:%S')
    main()
    print time.strftime('%Y-%m-%d %H:%M:%S')
