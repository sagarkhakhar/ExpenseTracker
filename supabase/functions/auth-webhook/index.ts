import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

interface AuthWebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: any
  schema: string
  old_record?: any
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, webhook-signature',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { 
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }

  try {
    // Verify webhook signature if configured
    const webhookSecret = Deno.env.get('WEBHOOK_SECRET')
    if (webhookSecret) {
      const signature = req.headers.get('webhook-signature')
      if (!signature) {
        return new Response(
          JSON.stringify({ error: 'Missing webhook signature' }),
          { 
            status: 401,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }
      // Note: In production, implement proper signature verification
    }

    const payload: AuthWebhookPayload = await req.json()

    // Create service role Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log('Auth webhook received:', {
      type: payload.type,
      table: payload.table,
      record_id: payload.record?.id
    })

    // Handle different auth events
    switch (payload.type) {
      case 'INSERT':
        if (payload.table === 'users') {
          return await handleUserSignup(supabaseClient, payload.record)
        }
        break
      
      case 'UPDATE':
        if (payload.table === 'users') {
          return await handleUserUpdate(supabaseClient, payload.record, payload.old_record)
        }
        break
      
      case 'DELETE':
        if (payload.table === 'users') {
          return await handleUserDeletion(supabaseClient, payload.old_record)
        }
        break
      
      default:
        console.log('Unhandled webhook event:', payload.type)
    }

    return new Response(
      JSON.stringify({ message: 'Webhook processed' }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error processing auth webhook:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function handleUserSignup(supabaseClient: any, user: any) {
  try {
    console.log('Processing user signup:', user.id)

    // Extract user information
    const userEmail = user.email
    const userMetadata = user.raw_user_meta_data || {}
    const displayName = userMetadata.display_name || userEmail?.split('@')[0] || 'User'

    // Create user profile
    const { error: profileError } = await supabaseClient
      .from('user_profiles')
      .upsert({
        id: user.id,
        display_name: displayName,
        currency: userMetadata.currency || 'USD',
        date_format: userMetadata.date_format || 'MM/dd/yyyy',
        first_day_of_week: userMetadata.first_day_of_week || 0,
        device_id: 'auth-webhook',
        last_editor: 'system'
      }, {
        onConflict: 'id'
      })

    if (profileError) {
      console.error('Failed to create user profile:', profileError)
      throw profileError
    }

    // Get shared categories
    const { data: sharedCategories, error: categoriesError } = await supabaseClient
      .from('shared_categories')
      .select('name, icon, color, sort_order')
      .eq('is_deleted', false)
      .order('sort_order')

    if (categoriesError) {
      console.error('Failed to fetch shared categories:', categoriesError)
    }

    // Create default personal categories from shared categories
    if (sharedCategories && sharedCategories.length > 0) {
      const userCategories = sharedCategories.map((cat: any) => ({
        name: cat.name,
        icon: cat.icon,
        color: cat.color,
        user_id: user.id,
        device_id: 'auth-webhook',
        last_editor: 'system'
      }))

      const { error: insertCategoriesError } = await supabaseClient
        .from('categories')
        .upsert(userCategories, {
          onConflict: 'name,user_id',
          ignoreDuplicates: true
        })

      if (insertCategoriesError) {
        console.error('Failed to create user categories:', insertCategoriesError)
      } else {
        console.log(`Created ${userCategories.length} categories for user ${user.id}`)
      }
    }

    // Create default accounts
    const defaultAccounts = [
      {
        name: 'Cash',
        type: 'cash',
        balance: 0.00,
        user_id: user.id,
        device_id: 'auth-webhook',
        last_editor: 'system'
      },
      {
        name: 'Bank Account',
        type: 'bank',
        balance: 0.00,
        user_id: user.id,
        device_id: 'auth-webhook',
        last_editor: 'system'
      }
    ]

    const { error: accountError } = await supabaseClient
      .from('accounts')
      .upsert(defaultAccounts, {
        onConflict: 'name,user_id',
        ignoreDuplicates: true
      })

    if (accountError) {
      console.error('Failed to create default accounts:', accountError)
    } else {
      console.log(`Created ${defaultAccounts.length} accounts for user ${user.id}`)
    }

    // Log the successful initialization
    const { error: auditError } = await supabaseClient
      .from('security_audit_log')
      .insert({
        user_id: user.id,
        table_name: 'auth.users',
        operation: 'USER_SIGNUP',
        record_id: user.id,
        new_values: {
          email: userEmail,
          display_name: displayName,
          categories_created: sharedCategories?.length || 0,
          accounts_created: defaultAccounts.length
        }
      })

    if (auditError) {
      console.error('Failed to log audit event:', auditError)
    }

    console.log('User initialization completed successfully for:', user.id)

    return new Response(
      JSON.stringify({ 
        message: 'User initialized successfully',
        user_id: user.id,
        categories_created: sharedCategories?.length || 0,
        accounts_created: defaultAccounts.length
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error in handleUserSignup:', error)
    
    // Log the error for monitoring
    try {
      await supabaseClient
        .from('security_audit_log')
        .insert({
          user_id: user.id,
          table_name: 'auth.users',
          operation: 'USER_SIGNUP_ERROR',
          record_id: user.id,
          new_values: {
            error: error.message,
            stack: error.stack
          }
        })
    } catch (auditError) {
      console.error('Failed to log signup error:', auditError)
    }

    return new Response(
      JSON.stringify({ 
        error: 'Failed to initialize user',
        details: error.message,
        user_id: user.id
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function handleUserUpdate(supabaseClient: any, user: any, oldUser: any) {
  try {
    console.log('Processing user update:', user.id)

    // Check if email was confirmed
    const wasEmailConfirmed = !oldUser.email_confirmed_at && user.email_confirmed_at
    const emailChanged = oldUser.email !== user.email

    if (wasEmailConfirmed) {
      console.log('Email confirmed for user:', user.id)
      
      // Update user profile if needed
      const { error: profileError } = await supabaseClient
        .from('user_profiles')
        .update({
          last_editor: 'email-confirmation',
          updated_at: new Date().toISOString()
        })
        .eq('id', user.id)

      if (profileError) {
        console.error('Failed to update profile on email confirmation:', profileError)
      }
    }

    if (emailChanged) {
      console.log('Email changed for user:', user.id, 'from', oldUser.email, 'to', user.email)
    }

    // Log the update event
    const { error: auditError } = await supabaseClient
      .from('security_audit_log')
      .insert({
        user_id: user.id,
        table_name: 'auth.users',
        operation: 'USER_UPDATE',
        record_id: user.id,
        old_values: {
          email: oldUser.email,
          email_confirmed_at: oldUser.email_confirmed_at
        },
        new_values: {
          email: user.email,
          email_confirmed_at: user.email_confirmed_at,
          email_confirmed: wasEmailConfirmed,
          email_changed: emailChanged
        }
      })

    if (auditError) {
      console.error('Failed to log user update audit event:', auditError)
    }

    return new Response(
      JSON.stringify({ 
        message: 'User update processed',
        user_id: user.id,
        email_confirmed: wasEmailConfirmed,
        email_changed: emailChanged
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error in handleUserUpdate:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Failed to process user update',
        details: error.message
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function handleUserDeletion(supabaseClient: any, oldUser: any) {
  try {
    console.log('Processing user deletion:', oldUser.id)

    // Note: User data cleanup is handled by CASCADE constraints
    // This webhook can be used for additional cleanup or notifications

    // Log the deletion event
    const { error: auditError } = await supabaseClient
      .from('security_audit_log')
      .insert({
        user_id: oldUser.id,
        table_name: 'auth.users',
        operation: 'USER_DELETE',
        record_id: oldUser.id,
        old_values: {
          email: oldUser.email,
          deleted_at: new Date().toISOString()
        }
      })

    if (auditError) {
      console.error('Failed to log user deletion audit event:', auditError)
    }

    console.log('User deletion processed successfully for:', oldUser.id)

    return new Response(
      JSON.stringify({ 
        message: 'User deletion processed',
        user_id: oldUser.id
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error in handleUserDeletion:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Failed to process user deletion',
        details: error.message
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}