import React from 'react';
import { View, Text, Image, Pressable, Dimensions, Platform, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import * as ScreenOrientation from 'expo-screen-orientation';

const { width: SCREEN_W } = Dimensions.get('window');
const ART = Math.min(SCREEN_W * 0.6, 340);

export function NowPlaying({ track }) {
  const insets = useSafeAreaInsets();
  const isWide = Platform.isPad;
  React.useEffect(() => { ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP); }, []);
  return (
    <View style={[styles.root, { paddingHorizontal: insets.left }]}>
      <View style={[styles.column, { width: isWide ? SCREEN_W / 2 : SCREEN_W }]}>
        <Image source={track.art} style={{ width: ART, height: ART, alignSelf: 'center' }} />
        <Text style={styles.title}>{track.title}</Text>
        <View style={styles.transport}>
          <Pressable style={styles.btn}><Text>⏮</Text></Pressable>
          <Pressable style={styles.btn}><Text>▶</Text></Pressable>
          <Pressable style={styles.btn}><Text>⏭</Text></Pressable>
        </View>
      </View>
      <View style={styles.bottomBar}>
        {['Lyrics', 'Queue', 'Share', 'AirPlay', '•••'].map(t => <Pressable key={t}><Text>{t}</Text></Pressable>)}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, alignItems: 'center' },
  column: { alignItems: 'center' },
  title: { fontSize: 22, textAlign: 'center' },
  transport: { flexDirection: 'row', justifyContent: 'center', gap: 40 },
  btn: { width: 72, height: 72, borderRadius: 36, backgroundColor: '#eee' },
  bottomBar: { position: 'absolute', bottom: 0, left: 0, right: 0, height: 56, flexDirection: 'row', justifyContent: 'space-around' },
});
